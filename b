/*
 * ac_signal.c
 * Optimize Edilmiş ISR (Kesme) Tabanlı Sürüm
 * Parçalı Doğrusal Genlik Haritalaması (Piecewise Linear Mapping)
 */

#include "ac_signal.h"
#include <math.h> // sinf() ve M_PI için

#ifndef M_PI
#define M_PI 3.14159265358979323846f
#endif

// 1kHz'de kilitlenmeyi önlemek için Örnek Sayısı 16'da tutuluyor.
#define SINE_LUT_SIZE 16

/* --- Statik (dahili) değişkenler --- */

static TIM_HandleTypeDef    *s_htim_ac = NULL; // AC Timer Handle
static MAXREFDES24_Device   *s_dev_ac  = NULL; // AC Çıkış Cihazı
static uint8_t              s_ch_ac  = 0;    // AC Çıkış Kanalı (0-3)

// Sinüs Arama Tablosu (float, -1.0 ila 1.0)
static float s_sine_lut[SINE_LUT_SIZE];

/* --- ISR tarafından kullanılan global değişkenler --- */
static volatile uint32_t s_sine_index = 0;
// Önceden hesaplanmış genlik (DAC adımı cinsinden)
static volatile int16_t  s_amplitude_dac_steps = 0; 

/* --- Fonksiyon Gövdeleri --- */

/**
 * @brief Sinüs sinyal üretecini başlatır.
 */
void AC_Signal_Init(TIM_HandleTypeDef *htim, MAXREFDES24_Device *dev, uint8_t channel)
{
    s_htim_ac = htim;
    s_dev_ac  = dev;
    s_ch_ac   = channel;

    // Sinüs arama tablosunu (-1.0 ile +1.0 arasında) doldur
    for (int i = 0; i < SINE_LUT_SIZE; i++)
    {
        s_sine_lut[i] = sinf(2.0f * M_PI * (float)i / (float)SINE_LUT_SIZE);
    }
    
    AC_Signal_Stop(); // Başlangıçta durduğundan ve çıkışın 0 olduğundan emin ol
}

/**
 * @brief Gelen komuta göre tepe genliğini hesaplar ve sinyali başlatır.
 */
void AC_Signal_Start(float amplitude_mA_cmd, uint32_t frequency_hz)
{
    // Önce timer'ı durdur
    HAL_TIM_Base_Stop_IT(s_htim_ac);

    /*
     * YENİ HESAPLAMA (Parçalı Doğrusal Haritalama)
     * Gelen komutu ('amplitude_mA_cmd') istenen tepe genliğine dönüştür.
     */
     
    float target_peak_mA; // Hedeflenen tepe akımı (örn: 2.22, 10, 20)

    if (amplitude_mA_cmd > 0.0f)
    {
        // 0 -> 10mA, +20 -> 20mA arasındaki hat
        // Eğim (Slope): (20.0f - 10.0f) / (20.0f - 0.0f) = 0.5f
        target_peak_mA = (0.5f * amplitude_mA_cmd) + 10.0f;
    }
    else if (amplitude_mA_cmd < 0.0f)
    {
        // -20 -> 2.22mA, 0 -> 10mA arasındaki hat
        // Eğim (Slope): (10.0f - 2.22f) / (0.0f - (-20.0f)) = 0.389f
        target_peak_mA = (0.389f * amplitude_mA_cmd) + 10.0f;
    }
    else // amplitude_mA_cmd == 0.0f
    {
        target_peak_mA = 10.0f;
    }

    // Donanım limitini (20mA) aşmadığımızdan emin ol (zaten aşmıyor ama kontrolü iyi)
    // const float HARDWARE_MAX_CURRENT = 20.0f;
    // if (target_peak_mA > HARDWARE_MAX_CURRENT) {
    //     target_peak_mA = HARDWARE_MAX_CURRENT;
    // }


    /*
     * Şimdi bu 'target_peak_mA' değerini DAC adımına çevirelim
     * (Bu, "Yöntem 2" optimizasyonunun anahtarıdır)
     */
     
    // Ölçek: $\pm20\text{mA}$ (donanımın max genliği) = 32767 adım (DAC'ın max genliği)
    const float scale = 32767.0f / 20.0f; 
    
    // Not: s_amplitude_dac_steps her zaman POZİTİF bir genliktir.
    // (Negatif komutlar sadece farklı bir pozitif genlik üretir)
    s_amplitude_dac_steps = (int16_t)(target_peak_mA * scale);


    // Eğer frekans 0 ise veya genlik 0 ise, sinyali durdur ve çık
    if (frequency_hz == 0 || s_amplitude_dac_steps == 0)
    {
        AC_Signal_Stop();
        return;
    }

    /* --- Geri kalan Timer/Frekans ayarları TAMAMEN AYNIDIR --- */

    // Timer'ın kesme frekansını hesapla
    uint32_t update_freq_hz = frequency_hz * SINE_LUT_SIZE;

    // Timer Periyodunu Dinamik Hesaplama
    uint32_t pclk = HAL_RCC_GetPCLK1Freq();
    uint32_t timer_clk = pclk;
    if ((RCC->CFGR & RCC_CFGR_PPRE1) != RCC_CFGR_PPRE1_DIV1)
    {
        timer_clk *= 2;
    }

    uint32_t period_ticks = timer_clk / update_freq_hz;
    uint16_t psc = (uint16_t)(period_ticks / 65536);
    uint16_t arr = (uint16_t)((period_ticks / (psc + 1)) - 1);

    // Yeni PSC ve ARR değerlerini timer'a yükle
    __HAL_TIM_SET_PRESCALER(s_htim_ac, psc);
    __HAL_TIM_SET_AUTORELOAD(s_htim_ac, arr);
    
    /* --- Timer'ı Başlat --- */
    s_sine_index = 0;                     // İndeksi sıfırla
    __HAL_TIM_SET_COUNTER(s_htim_ac, 0);  // Sayacı sıfırla
    
    // Timer'ı kesme modunda başlat
    HAL_TIM_Base_Start_IT(s_htim_ac);
}

/**
 * @brief AC sinyal üretimini durdurur ve çıkışı 0mA'e ayarlar.
 */
void AC_Signal_Stop(void)
{
    if (s_htim_ac) {
        HAL_TIM_Base_Stop_IT(s_htim_ac);
    }
    
    s_amplitude_dac_steps = 0;
    s_sine_index = 0;

    // Çıkışı 0mA'e ayarla (güvenlik için)
    if (s_dev_ac) {
        // 0mA = 32768 DAC kodu
        // (max24_setChannelDacValue, max24.c'ye eklediğimiz hızlı fonksiyondur)
        max24_setChannelDacValue(s_dev_ac, s_ch_ac, 32768);
    }
}

/**
 * @brief Bu fonksiyon, Timer kesmesi tarafından tetiklenir.
 * YAVAŞ FLOAT MATEMATİĞİ BURADAN ÇIKARILDI.
 */
void AC_Signal_Timer_ISR_Handler(void)
{
    if (s_dev_ac == NULL || s_amplitude_dac_steps == 0) {
        return;
    }

    // 1. Sinüs tablosundan mevcut değeri al (-1.0 ila 1.0)
    float sine_val = s_sine_lut[s_sine_index];

    // 2. Değeri önceden hesaplanmış DAC adımıyla ölçekle (Çok Hızlı İşlem)
    // (float * int -> float dönüşümü güvenli hale getirilmişti)
    float float_offset = sine_val * (float)s_amplitude_dac_steps;
    int16_t offset = (int16_t)float_offset;

    // 3. Nihai 16-bit DAC kodunu hesapla (Çok Hızlı İşlem)
    // 32768 = 0mA noktası
    uint16_t dacValue = 32768 + offset; 

    // 4. DAC'a değeri YENİ HIZLI FONKSİYON ile yaz
    max24_setChannelDacValue(s_dev_ac, s_ch_ac, dacValue);

    // 5. Bir sonraki indekse git (16'lık örnek için)
    s_sine_index = (s_sine_index + 1) & 15;
}
