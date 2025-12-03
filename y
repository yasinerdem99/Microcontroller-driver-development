
/*
 * Bootloader_raw.c
 * Yontem: DIRECT REGISTER POLLING (HAL Bypass)
 * Avantaj: HAL overhead yok, 0ms gecikmeye yetisir.
 */

#include "Bootloader_raw.h"
#include "Bootloader_flash.h"
#include "Bootloader_config.h"
#include <stdio.h>
#include <string.h>

extern UART_HandleTypeDef huart1; // UART1

/* --- RAM BUFFER --- */
#define RAW_BUFFER_SIZE  (128 * 1024)
static uint8_t g_raw_buffer[RAW_BUFFER_SIZE];
static uint32_t g_raw_len = 0;

/* Renkler */
#define CLR_RESET   "\033[0m"
#define CLR_CYAN    "\033[1;96m"
#define CLR_GREEN   "\033[1;92m"
#define CLR_RED     "\033[1;91m"
#define CLR_YELLOW  "\033[1;93m"

/* Değişkenler */
static uint32_t hex_upper_addr_raw = 0;

/* Global Slot Fonksiyonlari */
extern void Set_Active_Slot(uint32_t new_slot_flag);
extern uint32_t Get_Active_Slot_Addr(void);
extern void Bootloader_Jump_To_Address(uint32_t jump_addr); // Jump ekledik

/* ============================================================ */
/* YARDIMCI FONKSİYONLAR                                        */
/* ============================================================ */

static uint8_t Raw_HexCharToByte(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    return 0;
}

static uint8_t Raw_ParseByte(char* ptr) {
    return (Raw_HexCharToByte(ptr[0]) << 4) | Raw_HexCharToByte(ptr[1]);
}

/* Menü için HAL kullanmaya devam edebiliriz (Yavaş mod) */
static void Raw_Read_Line(char *buffer, uint16_t max_len) {
    uint16_t index = 0; uint8_t rx_char; memset(buffer, 0, max_len);
    while(1) {
        if (HAL_UART_Receive(&huart1, &rx_char, 1, HAL_MAX_DELAY) == HAL_OK) {
            if (rx_char == '\r' || rx_char == '\n') { printf("\r\n"); buffer[index] = 0; return; }
            if (index < max_len - 1) { buffer[index++] = rx_char; HAL_UART_Transmit(&huart1, &rx_char, 1, 10); }
        }
    }
}

static uint8_t Check_Address_Raw(uint32_t addr, uint32_t target_slot) {
    if (addr >= 0x08000000 && addr < 0x08010000) return 2;
    if (target_slot == SLOT_A_ADDR && addr >= 0x08010000 && addr < 0x08200000) return 1;
    if (target_slot == SLOT_B_ADDR && addr >= 0x08200000) return 1;
    return 0;
}

/* ============================================================ */
/* ANA FONKSIYON: RAW HEX YUKLEME (DIRECT ACCESS)               */
/* ============================================================ */
void Receive_Raw_Hex_File(void)
{
    uint8_t c;
    char line_buffer[512];
    uint16_t line_idx = 0;
    uint8_t in_line = 0;

    uint32_t target_slot_addr = 0;
    uint32_t target_slot = 0;
    char sub_cmd[10];

    /* Temizlik */
    memset(g_raw_buffer, 0xFF, RAW_BUFFER_SIZE);
    g_raw_len = 0;
    hex_upper_addr_raw = 0;
    
    /* Adres Yakalama */
    uint32_t detected_base_addr = 0xFFFFFFFF;
    uint8_t base_addr_locked = 0;

    /* 1. HEDEF SEÇİMİ */
    printf("\r\n" CLR_CYAN "[RAW MODU]" CLR_RESET " Slot Secimi (a/b) > ");
    fflush(stdout);
    Raw_Read_Line(sub_cmd, 10);

    if (strcmp(sub_cmd, "a") == 0 || strcmp(sub_cmd, "A") == 0) {
        target_slot = SLOT_A_ADDR; target_slot_addr = SLOT_A_ADDR;
        printf("HEDEF: SLOT A (0x%08X)\r\n", (unsigned int)target_slot_addr);
    }
    else if (strcmp(sub_cmd, "b") == 0 || strcmp(sub_cmd, "B") == 0) {
        target_slot = SLOT_B_ADDR; target_slot_addr = SLOT_B_ADDR;
        printf("HEDEF: SLOT B (0x%08X)\r\n", (unsigned int)target_slot_addr);
    }
    else { printf("\r\nIptal.\r\n"); return; }

    printf("\r\n" CLR_GREEN "[HAZIR] Dosyayi surukleyin... (Direct Register Mode)\r\n" CLR_RESET);

    /* --- KRİTİK AYARLAR --- */
    /* UART Interrupt'ını kapat (Çakışma olmasın) */
    __HAL_UART_DISABLE_IT(&huart1, UART_IT_RXNE);
    /* Hata bayraklarını temizle */
    __HAL_UART_CLEAR_OREFLAG(&huart1);

    uint32_t last_rx = HAL_GetTick();
    uint8_t data_started = 0;

    /* 2. VERİ YAKALAMA (SUPER FAST LOOP) */
    while(1)
    {
        /* HAL YOK! Direkt Register Kontrolü */
        /* ISR: Interrupt & Status Register, RXNE: Read Data Not Empty */
        if (huart1.Instance->ISR & UART_FLAG_RXNE)
        {
            /* Veriyi RDR (Receive Data Register)'dan çek */
            c = (uint8_t)(huart1.Instance->RDR); 
            
            last_rx = HAL_GetTick();
            
            /* Başlangıç Tespiti (Gürültü Filtresi) */
            if (!data_started) {
                if (c == ':') {
                    data_started = 1;
                    // İlk ':' geldi, kaydetmeye başla
                } else {
                    continue; 
                }
            }

            /* RAM'e Kayıt (Hızlı) */
            if (g_raw_len < RAW_BUFFER_SIZE) {
                g_raw_buffer[g_raw_len++] = c;
            }
            else {
                /* Buffer dolarsa çık */
                break; 
            }
        }
        else
        {
            /* Veri yoksa Timeout Kontrolü */
            /* Dosya başladıysa ve 1.5 sn veri gelmezse bitti say */
            if (data_started && (HAL_GetTick() - last_rx > 1500)) {
                break; 
            }
            
            /* OVERRUN (Taşma) Hatası Kontrolü */
            /* Eğer çok hızlı gelip taşarsa, bayrağı temizle ve devam et */
            if (huart1.Instance->ISR & UART_FLAG_ORE) {
                __HAL_UART_CLEAR_OREFLAG(&huart1);
            }
        }
    }

    /* İş bitti, Interrupt'ı geri aç (İlerde lazım olur) */
    __HAL_UART_ENABLE_IT(&huart1, UART_IT_RXNE);

    if (g_raw_len == 0) {
        printf("\r\n[HATA] Veri gelmedi.\r\n"); return;
    }

    printf("\r\n[INFO] Alindi: %lu Bytes. Cozumleniyor...\r\n", g_raw_len);

    /* --- 3. FLASH SİLME --- */
    printf("Flash Siliniyor...\r\n");
    if (Bootloader_Flash_Erase_Target_Slot(target_slot) == 0) {
        printf("\r\n[FAIL] Silme Hatasi!\r\n"); return;
    }

    printf("Flash Yaziliyor...\r\n");
    
    /* --- 4. PARSING VE YAZMA --- */
    uint8_t row_data[16];
    uint32_t i = 0;
    
    while (i < g_raw_len)
    {
        c = g_raw_buffer[i++];

        if (c == ':') { in_line = 1; line_idx = 0; line_buffer[line_idx++] = ':'; continue; }
        if (!in_line) continue;

        if (c == '\r' || c == '\n') 
        {
            in_line = 0;
            line_buffer[line_idx] = '\0';

            /* HEX Parsing */
            uint8_t count = Raw_ParseByte(&line_buffer[0]);
            uint16_t alow = (Raw_ParseByte(&line_buffer[2]) << 8) | Raw_ParseByte(&line_buffer[4]);
            uint8_t type  = Raw_ParseByte(&line_buffer[6]);

            /* Tip 04: Üst Adres */
            if (type == 0x04) {
                hex_upper_addr_raw = (Raw_ParseByte(&line_buffer[8]) << 8) | Raw_ParseByte(&line_buffer[10]);
            }
            /* Tip 00: Veri */
            else if (type == 0x00) {
                uint32_t abs_addr = (hex_upper_addr_raw << 16) | alow;
                
                /* Adres Kilitleme */
                if (!base_addr_locked) {
                    if(abs_addr >= 0x08000000) {
                        detected_base_addr = abs_addr;
                        base_addr_locked = 1;
                    }
                }

                if (base_addr_locked && abs_addr >= detected_base_addr)
                {
                    /* Offset Hesabı (Hedef slota göre kaydır) */
                    /* Örneğin dosya 0x0801.. ise ve hedef 0x0820.. ise aradaki farkı kapatır */
                    uint32_t offset = abs_addr - detected_base_addr;
                    uint32_t final_write_addr = target_slot_addr + offset;

                    /* Veriyi Hazırla */
                    for(int k=0; k<count; k++) {
                        row_data[k] = Raw_ParseByte(&line_buffer[8+(k*2)]);
                    }

                    /* Yaz */
                    if (Bootloader_Flash_Write(final_addr, row_data, count) == 0) {
                        printf("\r\n[FAIL] Yazma Hatasi! Adr: 0x%08X\r\n", (unsigned int)final_addr);
                        return;
                    }
                }
            }
            
            line_idx = 0;
        } 
        else {
            if (line_idx < 511) line_buffer[line_idx++] = c;
        }
    }

    /* 5. BİTİŞ */
    if (target_slot == SLOT_A_ADDR) Set_Active_Slot(SLOT_A_ACTIVE);
    else Set_Active_Slot(SLOT_B_ACTIVE);

    printf("\r\n\n" CLR_GREEN "[OK] RAW Yukleme Tamamlandi! Geciliyor..." CLR_RESET "\r\n");
    
    /* Direkt Jump (Reset atmadan) */
    Bootloader_Jump_To_Address(target_slot_addr);
}
