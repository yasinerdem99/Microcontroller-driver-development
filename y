/*
 * Bootloader_bin_raw.c
 * FEATURE: Auto Ping-Pong + 'e' Cancel + Polling (0ms Delay)
 *
 * Bu modül:
 * 1. Aktif Slotu okur, HEDEF olarak digerini secer (Otomatik).
 * 2. Kullanicidan 'e' gelirse iptal eder.
 * 3. Polling ile veriyi 0ms gecikmeyle RAM'e toplar (DMA gerektirmez, cok hizlidir).
 * 4. Dosya bitince (EOF) guvenlik kontrolu yapar ve Flash'a yazar.
 */

#include "Bootloader_hex_raw.h" // Veya Bootloader_bin_raw.h
#include "Bootloader_flash.h"
#include "Bootloader_config.h"
#include <stdio.h>
#include <string.h>

extern UART_HandleTypeDef huart1;

/* --- RAM BUFFER AYARLARI --- */
/* STM32U5'te bolca RAM var. 256 KB'lik dev bir alan ayiriyoruz. */
#define BIN_BUFFER_SIZE  (256 * 1024)

/* Buffer'ı ".bss" bölümüne koyuyoruz (Sıfırlanmamış RAM) */
static uint8_t g_bin_buffer[BIN_BUFFER_SIZE];
static uint32_t g_bin_len = 0;

/* --- RENK KODLARI --- */
#define CLR_RESET   "\033[0m"
#define CLR_CYAN    "\033[1;96m"
#define CLR_GREEN   "\033[1;92m"
#define CLR_RED     "\033[1;91m"
#define CLR_YELLOW  "\033[1;93m"

/* Slot Fonksiyonları */
extern void Set_Active_Slot(uint32_t new_slot_flag);
extern uint32_t Get_Active_Slot_Addr(void);

uint8_t rx_char_1 = 0;

/* ============================================================ */
/* ANA FONKSIYON: RECEIVE RAW BIN FILE                          */
/* ============================================================ */
void Receive_Raw_Bin_File(void)
{
    uint32_t target_slot_id = 0;   // SLOT_A_ADDR veya SLOT_B_ADDR (ID olarak kullaniliyor)
    uint32_t target_slot_addr = 0; // Yazilacak Flash adresi

    /* Temizlik */
    g_bin_len = 0;

    /* --- 1. OTOMATİK HEDEF SEÇİMİ (PING-PONG) --- */
    uint32_t current_active = Get_Active_Slot_Addr();

    printf("\r\n========================================\r\n");
    if (current_active == SLOT_A_ADDR) {
        target_slot_id = SLOT_B_ADDR;
        target_slot_addr = SLOT_B_ADDR;
        printf(" [INFO] Mevcut: SLOT A (Aktif)\r\n");
        printf(" [AUTO] HEDEF : SLOT B (0x%08lX)\r\n", target_slot_addr);
    } else {
        target_slot_id = SLOT_A_ADDR;
        target_slot_addr = SLOT_A_ADDR;
        printf(" [INFO] Mevcut: SLOT B (Aktif)\r\n");
        printf(" [AUTO] HEDEF : SLOT A (0x%08lX)\r\n", target_slot_addr);
    }
    printf("========================================\r\n");

    printf("Dikkat! Hedef Slot Silinecek. Onayliyor musunuz? (y/n) > \r\n");
    while(1) {
        HAL_UART_Receive(&huart1, &rx_char_1, 1, HAL_MAX_DELAY);
        if (rx_char_1 == 'y' || rx_char_1 == 'Y') break;
        if (rx_char_1 == 'n' || rx_char_1 == 'N') { printf("Iptal.\r\n"); return; }
    }

    printf(CLR_GREEN "[HAZIR] .bin dosyasini surukleyin... (Iptal icin 'e' tuslayin)\r\n" CLR_RESET);

    /* --- 2. VERİ YAKALAMA (ULTRA HIZLI DÖNGÜ) --- */

    /* Kesmeleri kapatiyoruz (Polling sirasinda baska kesme girmesin) */
    /* Not: HAL_GetTick durabilir, bu yuzden timeout'u sayacla yapabiliriz veya
       riski goze alip acik tutabiliriz. Bin dosyalari hizli aktigi icin acik kalabilir. */
    // __disable_irq();

    uint32_t last_rx = HAL_GetTick();
    uint8_t data_started = 0;

    while(1)
    {
        /* REGISTER LEVEL POLLING: En hızlı okuma yöntemi */
        if (__HAL_UART_GET_FLAG(&huart1, UART_FLAG_RXNE))
        {
            /* Veriyi direkt Register'dan al */
            uint8_t c = (uint8_t)(huart1.Instance->RDR & 0xFF);

            /* --- İPTAL KONTROLÜ ('e') --- */
            /* BIN dosyalarinda ilk byte'in 'e' (0x65) olma ihtimali dusuktur (Cortex-M MSP Stack genelde 0x20...00) */
            if (!data_started)
            {
                if (c == 'e' || c == 'E') {
                    printf("\r\n" CLR_RED "[IPTAL] Kullanici iptal etti." CLR_RESET "\r\n");
                    return;
                }
                data_started = 1;
            }

            /* RAM'e Kaydet */
            if (g_bin_len < BIN_BUFFER_SIZE) {
                g_bin_buffer[g_bin_len++] = c;
            }

            last_rx = HAL_GetTick();
        }
        else
        {
            /* Timeout Kontrolü: Veri başladıysa ve 1.5 sn kesildiyse BITTI demektir */
            if (data_started && (HAL_GetTick() - last_rx > 1500)) {
                break;
            }
        }
    }

    /* Kesmeler kapaliysa acilmalidir */
    // __enable_irq();

    if (g_bin_len == 0) {
        /* Kullanici hicbir sey gondermediyse sessizce cik veya uyari ver */
        // printf("\r\n[INFO] Veri gelmedi.\r\n");
        return;
    }

    printf("\r\n[INFO] Alindi: %lu Bytes. Analiz ediliyor...\r\n", g_bin_len);

    /* --- 3. GÜVENLİK KONTROLÜ (HEADER CHECK) --- */
    /* Bin dosyasının ilk 4 byte'ı Stack Pointer, sonraki 4 byte Reset Vector'dür */
    if (g_bin_len > 8)
    {
        uint32_t reset_vector = *((uint32_t*)&g_bin_buffer[4]); // 4. byte'tan başla

        /* Reset Vektörü Flash adres aralığında mı? (0x08...) */
        if (reset_vector < 0x08000000 || reset_vector > 0x08400000) {
            printf(CLR_RED "[HATA] Bu bir Binary dosya degil veya bozuk!\r\n" CLR_RESET);
            printf("Reset Vector: 0x%08lX (Gecersiz)\r\n", reset_vector);
            return;
        }

        /* Bootloader Koruması */
        if (reset_vector < 0x08010000) {
            printf(CLR_RED "[UYARI] Bootloader dosyasini yuklemeye calisiyorsunuz!\r\n" CLR_RESET);
        }

        printf("Dosya Hedef Adresi: 0x%08lX (Tahmini)\r\n", reset_vector);
    }

    /* --- 4. FLASH SİLME (Sadece Veri Tamamlandiginda) --- */
    printf("Hedef Slot (0x%X) Siliniyor...\r\n", target_slot_id);
    if (Bootloader_Flash_Erase_Target_Slot(target_slot_id) == 0) {
        printf("\r\n" CLR_RED "[FAIL] Silme Hatasi!" CLR_RESET "\r\n"); return;
    }

    /* --- 5. RAM -> FLASH YAZMA --- */
    printf("Yaziliyor...\r\n");

    uint32_t write_addr = target_slot_addr;
    uint32_t bytes_written = 0;

    while (bytes_written < g_bin_len)
    {
        /* 128 Byte'lık paketler halinde yaz (Hizalama için güvenli) */
        uint32_t chunk = 128;
        if (g_bin_len - bytes_written < 128) chunk = g_bin_len - bytes_written;

        if (Bootloader_Flash_Write(write_addr, &g_bin_buffer[bytes_written], chunk) == 0) {
            printf("\r\n" CLR_RED "[FAIL] Yazma Hatasi!" CLR_RESET "\r\n"); return;
        }
        write_addr += chunk; bytes_written += chunk;

        if (bytes_written % 4096 == 0) { printf("."); fflush(stdout); }
    }

    /* --- 6. AKTİF SLOTU DEĞİŞTİR VE RESETLE --- */
    if (target_slot_id == SLOT_A_ADDR) Set_Active_Slot(SLOT_A_ACTIVE);
    else Set_Active_Slot(SLOT_B_ACTIVE);

    printf("\r\n\n" CLR_GREEN "[OK] BIN Yukleme Tamamlandi! Sistem Resetleniyor..." CLR_RESET "\r\n");
    HAL_Delay(1000);
    HAL_NVIC_SystemReset();
}
