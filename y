#include "Bootloader_flash.h"
#include <string.h>
#include <stdio.h>

/* Bootloader_config.h veya main.h dosyanızda UART handle'ı tanımlı olmalı */
extern UART_HandleTypeDef huart1;

/* STM32U5A9 (4MB Device) Sabitleri */
#define FLASH_BANK2_START_ADDR  0x08200000
#define APP_NUM_PAGES_TO_ERASE  128  // 1MB Yer Açar

/* --- RAM FUNCTION TANIMLAMASI --- */
/* Bu makro, fonksiyonların Flash yerine RAM'de çalışmasını sağlar.
   Böylece Flash silinirken işlemci durmaz. */
#if defined (__GNUC__)
  #define __RAM_FUNC __attribute__((section(".RamFunc")))
#elif defined (__CC_ARM)
  #define __RAM_FUNC __attribute__((section("RamFunc")))
#endif

/**
  * @brief  Flash belleğe veri yazar (RAM'de çalışır, Kesme Korumalı).
  */
__RAM_FUNC uint8_t Bootloader_Flash_Write(uint32_t address, uint8_t *data, uint16_t len)
{
    /* 16 Byte'lık hizalı geçici buffer (QuadWord Yazma için şart) */
    uint32_t temp_data[4];

    /* ÖNEMLİ: İşleme girmeden UART gönderiminin bitmesini bekle */
    /* Aksi takdirde interrupts kapanınca print yarım kalır */
    while((huart1.Instance->ISR & UART_FLAG_TC) == 0);

    /* Hata Bayraklarını Temizle ve Kilit Aç */
    __HAL_FLASH_CLEAR_FLAG(FLASH_FLAG_ALL_ERRORS);
    HAL_FLASH_Unlock();

    /* Döngü 16'şar byte ilerler (STM32U5 QuadWord yazar) */
    for (int i = 0; i < len; i += 16)
    {
        /* 1. Buffer'ı tamamen 0xFF ile doldur (Padding) */
        memset(temp_data, 0xFF, 16);

        /* 2. Elimizdeki veriyi kopyala */
        uint16_t copy_len = (len - i) >= 16 ? 16 : (len - i);
        memcpy(temp_data, &data[i], copy_len);

        /* 3. KRİTİK BÖLGE: Kesmeleri Kapat */
        __disable_irq();

        /* 4. Yazma İşlemi */
        HAL_StatusTypeDef status = HAL_FLASH_Program(FLASH_TYPEPROGRAM_QUADWORD, address + i, (uint32_t)temp_data);

        /* 5. Kesmeleri Geri Aç */
        __enable_irq();

        /* Hata Kontrolü */
        if (status != HAL_OK)
        {
            uint32_t error_code = HAL_FLASH_GetError();
            HAL_FLASH_Lock();
            /* RAM fonksiyonundan çıktık, artık Flash meşgul değil, printf çalışır */
            // printf("\r\n[HATA] Yazma! Adr: 0x%08lX Err: 0x%X\r\n", address + i, (unsigned int)error_code);
            return 0;
        }
    }

    HAL_FLASH_Lock();
    return 1;
}

/**
  * @brief  Hedef slota ait sayfaları siler (RAM'de çalışır, Kesme Korumalı).
  */
__RAM_FUNC uint8_t Bootloader_Flash_Erase_Target_Slot(uint32_t slot_addr)
{
    FLASH_EraseInitTypeDef EraseInitStruct;
    uint32_t PageError;
    uint32_t StartPage;
    uint32_t BankNumber;

    /* 1. UART İletiminin bitmesini bekle (Printf havada kalmasın) */
    while((huart1.Instance->ISR & UART_FLAG_TC) == 0);

    /* Bank ve Sayfa Tespiti */
    if (slot_addr < FLASH_BANK2_START_ADDR)
    {
        BankNumber = FLASH_BANK_1;
        StartPage = (slot_addr - FLASH_BASE) / FLASH_PAGE_SIZE;
    }
    else
    {
        BankNumber = FLASH_BANK_2;
        StartPage = (slot_addr - FLASH_BANK2_START_ADDR) / FLASH_PAGE_SIZE;
    }

    HAL_FLASH_Unlock();
    __HAL_FLASH_CLEAR_FLAG(FLASH_FLAG_ALL_ERRORS);

    EraseInitStruct.TypeErase   = FLASH_TYPEERASE_PAGES;
    EraseInitStruct.Banks       = BankNumber;
    EraseInitStruct.Page        = StartPage;
    EraseInitStruct.NbPages     = APP_NUM_PAGES_TO_ERASE;

    /* --- KRİTİK BÖLGE BAŞLANGICI --- */
    __disable_irq(); // Kesmeleri Kapat

    /* 2. Silme İşlemi (RAM'den çalışıyor) */
    HAL_StatusTypeDef status = HAL_FLASHEx_Erase(&EraseInitStruct, &PageError);

    __enable_irq();  // Kesmeleri Aç
    /* --- KRİTİK BÖLGE SONU --- */

    if (status != HAL_OK)
    {
        HAL_FLASH_Lock();
        return 0;
    }

    /* 3. STM32U5 İÇİN CACHE TEMİZLİĞİ (Çok Önemli) */
    /* Flash içeriği değişti, Cache'i geçersiz kıl ki CPU yeni veriyi okusun */
    HAL_ICACHE_Invalidate();

    HAL_FLASH_Lock();
    return 1;
}
