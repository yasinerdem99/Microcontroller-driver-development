
#ifndef INC_GPIO_H_
#define INC_GPIO_H_

#include "stm32f407xx.h"
/*
 * @def_group  GPIO Pins
 *
 */


#define GPIO_PIN_0 			(uint16_t)(0x0001) // 0000 0000 0000 0001   GPIO Pin 0 selected
#define GPIO_PIN_1			(uint16_t)(0x0002) // 0000 0000 0000 0010	GPIO Pin 1 selected
#define GPIO_PIN_2 			(uint16_t)(0x0004) // 0000 0000 0000 0100   GPIO Pin 2 selected
#define GPIO_PIN_3 			(uint16_t)(0x0008) // 0000 0000 0000 1000   GPIO Pin 3 selected
#define GPIO_PIN_4 			(uint16_t)(0x0010) // 0000 0000 0001 0000 	GPIO Pin 4 selected
#define GPIO_PIN_5 			(uint16_t)(0x0020) // 0000 0000 0010 0000	GPIO Pin 5 selected
#define GPIO_PIN_6 			(uint16_t)(0x0040) // 0000 0000 0100 0000	GPIO Pin 6 selected
#define GPIO_PIN_7 			(uint16_t)(0x0080) // 0000 0000 1000 0000	GPIO Pin 7 selected
#define GPIO_PIN_8 			(uint16_t)(0x0100) // 0000 0001 0000 0000	GPIO Pin 8 selected
#define GPIO_PIN_9 			(uint16_t)(0x0200) // 0000 0010 0000 0000	GPIO Pin 9 selected
#define GPIO_PIN_10 		(uint16_t)(0x0400) // 0000 0100 0000 0000	GPIO Pin 10 selected
#define GPIO_PIN_11 		(uint16_t)(0x0800) // 0000 1000 0000 0000	GPIO Pin 11 selected
#define GPIO_PIN_12 		(uint16_t)(0x1000) // 0001 0000 0000 0000	GPIO Pin 12 selected
#define GPIO_PIN_13 		(uint16_t)(0x2000) // 0010 0000 0000 0000	GPIO Pin 13 selected
#define GPIO_PIN_14 		(uint16_t)(0x4000) // 0100 0000 0000 0000	GPIO Pin 14 selected
#define GPIO_PIN_15 		(uint16_t)(0x8000) // 1000 0000 0000 0000	GPIO Pin 15 selected
#define GPIO_PIN_All 		(uint16_t)(0xFFFF) // 1000 0000 0000 0000	GPIO All Pin selected


/*
 * @def_group  GPIO_Pin_Modes
 *
 */

#define GPIO_Mode_Input		(0x0U)
#define GPIO_Mode_Output	(0x1U)
#define GPIO_Mode_AF		(0x2U)
#define GPIO_Mode_Analog	(0x3U)

/*
 * @def_group  GPIO_OTYPE_Modes
 *
 */

#define GPIO_OTYPE_PP		(0x0U)
#define GPIO_OTYPE_OD		(0x1U)

/*
 * @def_group  GPIO_PuPd_Modes
 *
 */

#define GPIO_PuPd_NOPULL	(0x0U)
#define GPIO_PuPd_PULLUP	(0x1U)
#define GPIO_PuPd_PULLDOWN	(0x2U)

/*
 * @def_group  GPIO_Speed_Modes
 *
 */

#define GPIO_SPEED_LOW		(0x0U)
#define GPIO_SPEED_MEDIUM	(0x1U)
#define GPIO_SPEED_HIGH		(0x2U)
#define GPIO_SPEED_VERY		(0x3U)


/*
 *
 * @def_group GPIO_AF_Modes
 *
 *
 */

#define GPIO_AF0			(0x0U)
#define GPIO_AF1			(0x1U)
#define GPIO_AF2			(0x2U)
#define GPIO_AF3			(0x3U)
#define GPIO_AF4			(0x4U)
#define GPIO_AF5			(0x5U)
#define GPIO_AF6			(0x6U)
#define GPIO_AF7			(0x7U)
#define GPIO_AF8			(0x8U)
#define GPIO_AF9			(0x9U)
#define GPIO_AF10			(0xAU)
#define GPIO_AF11			(0xBU)
#define GPIO_AF12			(0xCU)
#define GPIO_AF13			(0xDU)
#define GPIO_AF14			(0xEU)
#define GPIO_AF15			(0xFU)


typedef enum{

	GPIO_Pin_Reset = 0x0U,
	GPIO_Pin_Set = !GPIO_Pin_Reset

}GPIO_PinState_t;



typedef struct {


	uint32_t pinNumber; // GPIO Pin Numbers @def_group GPIO_Pins
	uint32_t Mode;		// GPIO Pin Numbers @def_group GPIO_Pin_Modes
	uint32_t Otype;		// GPIO Pin Numbers @def_group GPIO_OTYPE_Modes
	uint32_t PuPd;		// GPIO Pin Numbers @def_group GPIO_PuPd_Modes
	uint32_t Speed;		// GPIO Pin Numbers @def_group GPIO_Speed_Modes
	uint32_t Alternate; // GPIO Pin Numbers @def_group GPIO_AF_Modes



}GPIO_InitTypeDef_t;


void GPIO_Init(GPIO_TypeDef_t *GPIOx,GPIO_InitTypeDef_t *GPIO_ConfigStruct);
void GPIO_WritePin(GPIO_TypeDef_t *GPIOx, uint16_t pinNumber,GPIO_PinState_t pinState);
GPIO_PinState_t GPIO_ReadPin(GPIO_TypeDef_t *GPIOx, uint16_t pinNumber);
void LockPin(GPIO_TypeDef_t *GPIOx, uint16_t pinNumber);
void GPIO_TogglePin(GPIO_TypeDef_t *GPIOx, uint16_t pinNumber);


#endif /* INC_GPIO_H_ */
