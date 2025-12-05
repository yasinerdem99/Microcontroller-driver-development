/*
 * Bootloader_bin_raw.c
 * FEATURE: Auto Ping-Pong + Polling (0ms) + ADDRESS SECURITY CHECK
 */

#include "Bootloader_hex_raw.h" // Veya Bootloader_bin_raw.h
#include "Bootloader_flash.h"
#include "Bootloader_config.h"
#include <stdio.h>
#include <string.h>

extern UART_HandleTypeDef huart1;

/* --- RAM BUFFER (256KB) --- */
#define BIN_BUFFER_SIZE  (256 * 1024)
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

uint8_t rx_char_bin = 0; // Değişken adı karışmasın diye _bin ekledim

/* ============================================================ */
/* ANA FONKSIYON: RECEIVE RAW BIN FILE                          */
/* ============================================================ */
void Receive_Raw_Bin_File(void)
{
    uint32_t target_slot_id = 0;
    uint32_t target_slot_addr = 0;

    /* Temizlik */
    g_bin_len = 0;

    /* --- 1. OTOMATİK HEDEF SEÇİMİ --- */
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
        HAL_UART_Receive(&huart1, &rx_char_bin, 1, HAL_MAX_DELAY);
        if (rx_char_bin == 'y' || rx_char_bin == 'Y') break;
        if (rx_char_bin == 'n' || rx_char_bin == 'N') { printf("Iptal.\r\n"); return; }
    }

    printf(CLR_GREEN "[HAZIR] .bin dosyasini surukleyin... (Iptal icin 'e' tuslayin)\r\n" CLR_RESET);

    /* --- 2. VERİ YAKALAMA (POLLING) --- */
    uint32_t last_rx = HAL_GetTick();
    uint8_t data_started = 0;

    while(1)
    {
        if (__HAL_UART_GET_FLAG(&huart1, UART_FLAG_RXNE))
        {
            uint8_t c = (uint8_t)(huart1.Instance->RDR & 0xFF);

            /* İptal Kontrolü */
            if (!data_started) {
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
            /* Timeout: 1.5 sn */
            if (data_started && (HAL_GetTick() - last_rx > 1500)) {
                break; // Dosya bitti
            }
        }
    }

    if (g_bin_len == 0) {
        return;
    }

    printf("\r\n[INFO] Alindi: %lu Bytes. Analiz ediliyor...\r\n", g_bin_len);

    /* --- 3. GÜVENLİK KONTROLÜ (ADRES) --- */
    /* Bin dosyasının 4. ile 7. byte'ları Reset Vector (Başlangıç Adresi) dir */
    if (g_bin_len > 8)
    {
        /* RAM Buffer'dan adresi oku (Little Endian) */
        uint32_t reset_vector = 0;
        reset_vector |= g_bin_buffer[4];
        reset_vector |= (g_bin_buffer[5] << 8);
        reset_vector |= (g_bin_buffer[6] << 16);
        reset_vector |= (g_bin_buffer[7] << 24);

        printf("[ANALIZ] Dosya Reset Vektoru: 0x%08lX\r\n", reset_vector);

        /* Bootloader Koruması */
        if (reset_vector >= 0x08000000 && reset_vector < 0x08010000) {
            printf(CLR_RED "[KRITIK] Bootloader dosyasini yuklemeye calisiyorsunuz!\r\n" CLR_RESET);
            printf("Islem Iptal Edildi.\r\n");
            return;
        }

        /* Hedef Slot Kontrolü */
        uint8_t address_ok = 0;

        if (target_slot_id == SLOT_A_ADDR) {
            // Hedef A ise, adres A sınırlarında olmalı
            if (reset_vector >= 0x08010000 && reset_vector < 0x08200000) address_ok = 1;
        }
        else if (target_slot_id == SLOT_B_ADDR) {
            // Hedef B ise, adres B sınırlarında olmalı
            if (reset_vector >= 0x08200000) address_ok = 1;
        }

        if (address_ok == 0) {
            printf("\r\n" CLR_RED "[HATA] ADRES UYUSMAZLIGI!" CLR_RESET "\r\n");
            printf("Dosya Adresi : 0x%08lX\r\n", reset_vector);
            printf("Hedef Slot   : 0x%08lX\r\n", target_slot_addr);
            printf("Bu dosya, secilen slot icin derlenmemis.\r\n");
            return; // ÇIKIŞ (Silme yapma)
        }
    }
    else {
        printf(CLR_RED "[HATA] Dosya cok kucuk (Header yok)!\r\n" CLR_RESET);
        return;
    }

    /* --- 4. FLASH SİLME (Artık güvenli) --- */
    printf("Adres Dogru. Flash Siliniyor...\r\n");
    if (Bootloader_Flash_Erase_Target_Slot(target_slot_id) == 0) {
        printf("\r\n" CLR_RED "[FAIL] Silme Hatasi!" CLR_RESET "\r\n"); return;
    }

    /* --- 5. FLASH YAZMA --- */
    printf("Yaziliyor...\r\n");
    uint32_t write_addr = target_slot_addr;
    uint32_t bytes_written = 0;

    while (bytes_written < g_bin_len)
    {
        uint32_t chunk = 128;
        if (g_bin_len - bytes_written < 128) chunk = g_bin_len - bytes_written;

        if (Bootloader_Flash_Write(write_addr, &g_bin_buffer[bytes_written], chunk) == 0) {
            printf("\r\n" CLR_RED "[FAIL] Yazma Hatasi!" CLR_RESET "\r\n"); return;
        }
        write_addr += chunk; bytes_written += chunk;

        if (bytes_written % 4096 == 0) { printf("."); fflush(stdout); }
    }

    /* --- 6. BİTİŞ --- */
    if (target_slot_id == SLOT_A_ADDR) Set_Active_Slot(SLOT_A_ACTIVE);
    else Set_Active_Slot(SLOT_B_ACTIVE);

    printf("\r\n\n" CLR_GREEN "[OK] BIN Yukleme Tamamlandi! Sistem Resetleniyor..." CLR_RESET "\r\n");
    HAL_Delay(1000);
    HAL_NVIC_SystemReset();
}
