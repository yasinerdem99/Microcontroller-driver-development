/*
 * ac_signal.c
 * Sürüm: Orijinal (Yavaş ISR) Fonksiyon Yapısı
 * Genlik: Parçalı Doğrusal Haritalama (-20/0/+20 -> 2.22/10/20mA)
 */

#include "ac_signal.h"
#include <math.h> // sinf() ve M_PI için

#ifndef M_PI
#define M_PI 3.14159265358979323846f
#endif

/*
 * ÖNEMLİ: SINE_LUT_SIZE, 128'den 16'ya düşürüldü.
 * Bu, 1kHz'de 'max24_setChannelCurrent' (yavaş fonksiyon) çağrılırken 
 * kilitlenmeyi (live-lock) önlemek için T_period'u uzatır.
 */
#define SINE_LUT_SIZE 16

/* --- Statik (dahili) değişkenler --- */

static TIM_HandleTypeDef    *s_htim_ac = NULL; // AC Timer Handle
static MAXREFDES24_Device   *s_dev_ac  = NULL; // AC Çıkış Cihazı
static uint8_t              s_ch_ac  = 0;    // AC Çıkış Kanalı (0-3)

// Sinüs Arama Tablosu (LUT)
static float s_sine_lut[SINE_LUT_SIZE];

// ISR tarafından kullanılan global değişkenler
static volatile uint32_t s_sine_index = 0;
// ISR, bu değişkene kaydedilen TEPESİ (peak) akımını kullanacak
static volatile float    s_ac_amplitude_ma = 0.0f;

/* --- Fonksiyon Gövdeleri --- */

/**
 * @brief Sinüs sinyal üretecini başlatır.
 */
void AC_Signal_Init(TIM_HandleTypeDef *htim, MAXREFDES24_Device *dev, uint8_t channel)
{
    s_htim_ac = htim;
    s_dev_ac  = dev;
    s_ch_ac   = channel;

    // Sinüs arama tablosunu (-1.0 ile +1.0 arasında) doldur (16 adım için)
    for (int i = 0; i < SINE_LUT_SIZE; i++)
    {
        s_sine_lut[i] = sinf(2.0f * M_PI * (float)i / (float)SINE_LUT_SIZE);
    }

    AC_Signal_Stop(); // Başlangıçta durduğundan ve çıkışın 0 olduğundan emin ol
}

/**
 * @brief Gelen komuta (-20/0/+20) göre tepe genliğini (2.22/10/20mA) 
 * hesaplar ve s_ac_amplitude_ma'ya kaydeder, sinyali başlatır.
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

    // Donanım limitini (20mA) aşmadığımızdan emin ol 
    if (target_peak_mA > 20.0f) {
        target_peak_mA = 20.0f;
    }

    // Bu hesaplanan tepe akımını, ISR'nin kullanması için global değişkene ata
    s_ac_amplitude_ma = target_peak_mA;


    // Eğer frekans 0 ise veya genlik 0 ise, sinyali durdur ve çık
    if (frequency_hz == 0 || s_ac_amplitude_ma == 0.0f)
    {
        AC_Signal_Stop();
        return;
    }

    /* --- Geri kalan Timer/Frekans ayarları TAMAMEN AYNIDIR --- */

    // Timer'ın kesme frekansını hesapla
    uint32_t update_freq_hz = frequency_hz * SINE_LUT_SIZE; // SINE_LUT_SIZE=16

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

    s_ac_amplitude_ma = 0.0f;
    s_sine_index = 0;

    // Çıkışı 0mA'e ayarla (güvenlik için)
    if (s_dev_ac) {
        // Orijinal (YAVAŞ) fonksiyonu çağırıyoruz
        max24_setChannelCurrent(s_dev_ac, s_ch_ac, 0.0f);
    }
}

/**
 * @brief Bu fonksiyon, Timer kesmesi tarafından tetiklenir.
 * Bu sürüm, yavaş olan 'max24_setChannelCurrent' fonksiyonunu çağırır.
 */
void AC_Signal_Timer_ISR_Handler(void)
{
    // Hata kontrolü veya sinyal durmuşsa
    if (s_dev_ac == NULL || s_ac_amplitude_ma == 0.0f) {
        return;
    }

    // 1. Sinüs tablosundan mevcut değeri al (-1.0 ila 1.0)
    float sine_val = s_sine_lut[s_sine_index];

    // 2. Değeri, AC_Signal_Start'ta hesaplanan TEPESİ ile ölçekle
    float current_mA = sine_val * s_ac_amplitude_ma;

    // 3. DAC'a (MAX24) değeri YAVAŞ (float matematiği içeren) fonksiyon ile yaz
    max24_setChannelCurrent(s_dev_ac, s_ch_ac, current_mA);

    // 4. Tablodaki bir sonraki indekse git
    //    SINE_LUT_SIZE (16) 2'nin kuvveti olduğu için s_sine_index % 16
    //    yerine (s_sine_index + 1) & 15 kullanabiliriz. (Daha hızlı)
    s_sine_index = (s_sine_index + 1) & (SINE_LUT_SIZE - 1); // (16 - 1 = 15)
}
