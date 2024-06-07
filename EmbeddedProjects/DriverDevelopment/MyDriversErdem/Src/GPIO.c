#include "GPIO.h"

/**
 *  @brief GPIO_Init,Configures the port and pin
 * 	@param GPIOx = GPIO Port Base Address
 *
 * 	@param GPIO_InitTypeDef_t = User Config Structures
 *
 * 	@retval Void
 *
 */

void GPIO_Init(GPIO_TypeDef_t *GPIOx,GPIO_InitTypeDef_t *GPIO_ConfigStruct)
{
	uint32_t position;
	uint32_t fakePosition;
	uint32_t lastPosition;


	for(position=0; position<16; position++)
	{

		fakePosition = (0x1 << position);
		lastPosition = (uint32_t)(GPIO_ConfigStruct->pinNumber) & fakePosition;

		if(fakePosition==lastPosition)
		{
			/* MODE CONFIG */
			uint32_t tempValue = GPIOx->MODER;

			tempValue &= ~(0x3U << (position * 2));
			tempValue |= (GPIO_ConfigStruct->Mode << (position * 2) );

			GPIOx->MODER = tempValue;

			if(GPIO_ConfigStruct->Mode ==GPIO_Mode_Output || GPIO_ConfigStruct->Mode == GPIO_Mode_AF)
			{
				/*Output Type Config */
				tempValue = GPIOx->OTYPER;
				tempValue &= ~(0x1U << position);
				tempValue |= (GPIO_ConfigStruct->Otype << position);
				GPIOx->OTYPER=tempValue;

				/*Output Speed Config */
				tempValue = GPIOx->OSPEEDR;
				tempValue &= ~(0x3U << (position*2));
				tempValue |= (GPIO_ConfigStruct->Speed << (position*2));
				GPIOx->OSPEEDR=tempValue;

			}

			/*Push Pull Config */
			tempValue = GPIOx->PUPDR;
			tempValue &= ~(0x3U << (position*2));
			tempValue |= (GPIO_ConfigStruct->PuPd << (position*2));
			GPIOx->PUPDR=tempValue;

			if(GPIO_ConfigStruct->Mode == GPIO_Mode_AF)
			{
			tempValue = GPIOx->AFR[position >> 3U];
			tempValue &= ~(0xFU << ((position & 0x7U) * 4));
			tempValue |= (GPIO_ConfigStruct->Alternate << ((position & 0x7U) * 4));
			GPIOx->AFR[position >> 3U] = tempValue;
			}
		}


	}
}


/**
 *  @brief GPIO_Write_Pin, makes pin high or low
 * 	@param GPIOx = GPIO Port Base Address
 *
 * 	@param pinNumber = GPIO Pin Numbers
 *
 * 	@param pinState = GPIO_Pin_Set or GPIO_Pin_Reset
 *
 * 	@retval Void
 *
 */

void GPIO_WritePin(GPIO_TypeDef_t *GPIOx, uint16_t pinNumber,GPIO_PinState_t pinState)
{
	if(pinState == GPIO_Pin_Set)
	{
		GPIOx->BSRR = pinNumber;


	}
	else
	{
		GPIOx->BSRR = (pinNumber << 16U);
	}
}

/**
 *  @brief GPIO_Read_Pin, reads the pin of GPIOx Port
 * 	@param GPIOx = GPIO Port Base Address
 *
 * 	@param pinNumber = GPIO Pin Numbers 0-15
 *
 *
 *
 * 	@retval GPIO_PinState_t
 *
 */

GPIO_PinState_t GPIO_ReadPin(GPIO_TypeDef_t *GPIOx, uint16_t pinNumber)
{
	GPIO_PinState_t bitStatus = GPIO_Pin_Reset;

	if((GPIOx->IDR & pinNumber)	!= GPIO_Pin_Reset)
	{
		bitStatus = GPIO_Pin_Set;
	}

	return bitStatus;
}
/**
 *  @brief GPIO_Lock_Pin, Lock the pin of GPIOx Port
 * 	@param GPIOx = GPIO Port Base Address
 *
 * 	@param pinNumber = GPIO Pin Numbers 0-15
 *
 *
 *
 * 	@retval void
 *
 */
void LockPin(GPIO_TypeDef_t *GPIOx, uint16_t pinNumber)
{
	uint32_t tempValue = (0x1U << 16U) | pinNumber; // 1 0000 1010 0000 0100

	GPIOx->LCKR = tempValue; // LCKR[16]= '1'  LCKR[15:0]= DATA
	GPIOx->LCKR = pinNumber; // LCKR[16]= '0'  LCKR[15:0]= DATA
	GPIOx->LCKR = tempValue; // LCKR[16]= '1'  LCKR[15:0]= DATA
	tempValue = GPIOx->LCKR; // Read Lock Register


}
/**
 *  @brief GPIO_Toggle_Pin, Toggles the pin of GPIOx Port
 * 	@param GPIOx = GPIO Port Base Address
 *
 * 	@param pinNumber = GPIO Pin Numbers 0-15
 *
 *
 *
 * 	@retval void
 *
 */
void GPIO_TogglePin(GPIO_TypeDef_t *GPIOx, uint16_t pinNumber)
{

	uint32_t tempODRRegister = GPIOx->ODR;

	GPIOx->BSRR = ((tempODRRegister & pinNumber) << 16U) | (~ tempODRRegister & pinNumber);


}

