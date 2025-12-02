/* --- RING BUFFER (HAVUZ) DEĞİŞKENLERİ --- */
/* Bu kısmı dosyanın en tepesine, diğer static değişkenlerin yanına ekle */
#define RING_BUFFER_SIZE  4096 

static uint8_t  rb_data[RING_BUFFER_SIZE];
static volatile uint16_t rb_head = 0;
static volatile uint16_t rb_tail = 0;
static uint8_t  rx_byte_it; // Interrupt için geçici değişken
