#include "SPI.h"


/**
 *  @brief SPI_CloseISR_TX, Disables the interrupt for transmission
 *
 * 	@param SPI_Handle = User config structure
 *
 * 	@retval Void
 *
 */

static void SPI_CloseISR_TX(SPI_HandleTypeDef_t *SPI_Handle)
{
	SPI_Handle->Instance->CR2 &= ~(0x1U << SPI_CR2_TXEIE);
	SPI_Handle->TxDataSize = 0;
	SPI_Handle->pTxDataAddr = NULL;
	SPI_Handle->busStateTx = SPI_BUS_FREE;

}
/**
 *  @brief SPI_CloseISR_RX, Disables the interrupt for reception
 *
 * 	@param SPI_Handle = User config structure
 *
 * 	@retval Void
 *
 */
static void SPI_CloseISR_RX(SPI_HandleTypeDef_t *SPI_Handle)
{
	SPI_Handle->Instance->CR2 &= ~(0x1U << SPI_CR2_RXNEIE);
	SPI_Handle->RxDataSize = 0;
	SPI_Handle->pRxDataAddr = NULL;
	SPI_Handle->busStateRx = SPI_BUS_FREE;

}
/**
 *  @brief SPI_TransmitHelper_16Bits, Stores the user data into the DR register for 16 bits formats
 *
 * 	@param SPI_Handle = User config structure
 *
 * 	@retval Void
 *
 */
static void SPI_TransmitHelper_16Bits(SPI_HandleTypeDef_t *SPI_Handle)
{
	SPI_Handle->Instance->DR = *((uint16_t*)(SPI_Handle->pTxDataAddr));
	SPI_Handle->pTxDataAddr += sizeof(uint16_t);
	SPI_Handle->TxDataSize -=2;

	if(SPI_Handle->TxDataSize == 0)
	{
		SPI_CloseISR_TX(SPI_Handle);
	}

}
/**
 *   @brief SPI_TransmitHelper_16Bits, Stores the user data into the DR register for 8 bits formats
 *
 * 	@param SPI_Handle = User config structure
 *
 * 	@retval Void
 *
 */
static void SPI_TransmitHelper_8Bits(SPI_HandleTypeDef_t *SPI_Handle)
{
	SPI_Handle->Instance->DR = *((uint8_t*)(SPI_Handle->pTxDataAddr));
	SPI_Handle->pTxDataAddr += sizeof(uint8_t);
	SPI_Handle->TxDataSize --;

	if(SPI_Handle->TxDataSize == 0)
	{
		SPI_CloseISR_TX(SPI_Handle);
	}

}
/**
 *   @brief SPI_ReceiveHelper_8Bits, Read the  data  register and stores into the user variable for 8 bits formats
 *
 * 	@param SPI_Handle = User config structure
 *
 * 	@retval Void
 *
 */
static void SPI_ReceiveHelper_8Bits(SPI_HandleTypeDef_t *SPI_Handle)
{
	*((uint8_t*)SPI_Handle->pRxDataAddr) = *((__IO uint8_t*)(&SPI_Handle->Instance->DR));
	SPI_Handle->pRxDataAddr += sizeof(uint8_t);
	SPI_Handle->RxDataSize --;

	if(SPI_Handle->RxDataSize == 0)
	{
		SPI_CloseISR_RX(SPI_Handle);
	}
}
/**
 *   @brief SPI_ReceiveHelper_16Bits, Read the  data  register and stores into the user variable for 16 bits formats
 *
 * 	@param SPI_Handle = User config structure
 *
 * 	@retval Void
 *
 */
static void SPI_ReceiveHelper_16Bits(SPI_HandleTypeDef_t *SPI_Handle)
{
	*((uint16_t*)SPI_Handle->pRxDataAddr) =(uint16_t) SPI_Handle->Instance->DR;
	SPI_Handle->pRxDataAddr += sizeof(uint16_t);
	SPI_Handle->RxDataSize -= 2;

	if(SPI_Handle->RxDataSize == 0)
	{
		SPI_CloseISR_RX(SPI_Handle);
	}
}
/**
 *  @brief SPI_Init,Configures the SPI Peripheral
 *
 * 	@param SPI_Handle = User config structure
 *
 * 	@retval Void
 *
 */

void SPI_Init(SPI_HandleTypeDef_t *SPI_Handle)
{

	uint32_t tempValue = 0;

	tempValue = SPI_Handle->Instance->CR1;

	tempValue |= (SPI_Handle->Init.BaudRate) | (SPI_Handle->Init.CPHA) |(SPI_Handle->Init.CPOL)  | (SPI_Handle->Init.DFF_Format)\
			      | (SPI_Handle->Init.Mode) | (SPI_Handle->Init.FrameFormat) | (SPI_Handle->Init.BusConfig) | (SPI_Handle->Init.SSM_Cmd);

	SPI_Handle->Instance->CR1 = tempValue;
}

/**
 *  @brief SPI_PeriphCmd,enable or disable SPI Peripheral
 *
 * 	@param SPI_Handle = User config structure
 *
 * 	@param stateofSPI = Enable or Disable
 *
 * 	@retval Void
 *
 */
void SPI_PeriphCmd(SPI_HandleTypeDef_t *SPI_Handle,FunctionalState_t stateofSPI)
{

	if(stateofSPI == ENABLE)
	{
		SPI_Handle->Instance->CR1 |= (0x1U << SPI_CR1_SPE);
	}
	else
	{
		SPI_Handle->Instance->CR1 &= ~(0x1U << SPI_CR1_SPE);
	}
}


/**
 *  @brief SPI_TransmitData ,Transmits data to the slave
 *
 * 	@param SPI_Handle = User config structure
 *
 * 	@param pdata = Address of data to send
 *
 *	@param sizeOfData = Length of your data in Bytes
 *
 * 	@retval Void
 *
 */


void SPI_TransmitData(SPI_HandleTypeDef_t *SPI_Handle, uint8_t *pData, uint16_t sizeOfData)
{

	if(SPI_Handle->Init.DFF_Format == SPI_DFF_16BITS)
	{
		while(sizeOfData > 0)
		{
			if(SPI_GetFlagStatus(SPI_Handle, SPI_TxE_FLAG))
			{
				SPI_Handle->Instance->DR = *( (uint16_t*)pData);
				pData += sizeof(uint16_t);
				sizeOfData -= 2;
			}
		}
	}
	else
	{
		while(sizeOfData > 0)
		{
			if(SPI_Handle->Instance->SR >> 1U & 0x1U)
			{
				SPI_Handle->Instance->DR = *pData;
				pData++;
				sizeOfData--;

			}
		}
	}

	while(SPI_GetFlagStatus(SPI_Handle, SPI_Busy_FLAG)); //wait for busy flag
}
/**
 *   @brief SPI_TransmitData_IT, Read the  data  from external world with interrupt method
 *
 * 	@param SPI_Handle = User config structure
 *
 * 	@param pData = carries the user data
 *
 * 	@param sizeOfData = Bytes number that we will send
 *
 * 	@retval Void
 *
 */

void SPI_TransmitData_IT(SPI_HandleTypeDef_t *SPI_Handle,uint8_t *pData, uint16_t sizeOfData)
{

	SPI_BusStatus_t busState = SPI_Handle->busStateTx;

	if(busState != SPI_BUS_BUSY_TX)
	{
		SPI_Handle->pTxDataAddr = (uint8_t*)pData;
		SPI_Handle->TxDataSize = (uint16_t)sizeOfData;
		SPI_Handle->busStateTx = SPI_BUS_BUSY_TX;

		if(SPI_Handle->Instance->CR1 & (0x01 << SPI_CR1_DFF))
		{
			SPI_Handle->TxISRFunction = SPI_TransmitHelper_16Bits;
		}
		else
		{
			SPI_Handle->TxISRFunction = SPI_TransmitHelper_8Bits;
		}

		SPI_Handle->Instance->CR2 |= (0x1U << SPI_CR2_TXEIE);
	}

}
/**
 *   @brief SPI_ReceiveData_IT, Read the  data  from external world with interrupt method
 *
 * 	@param SPI_Handle = User config structure
 *
 * 	@param pBuffer = Stores the data in the veriable
 *
 * 	@param sizeOfData = Bytes number that we will read
 *
 * 	@retval Void
 *
 */
void SPI_ReceiveData_IT(SPI_HandleTypeDef_t *SPI_Handle, uint8_t *pBuffer,uint16_t sizeOfData)
{

	SPI_BusStatus_t busState = SPI_Handle->busStateRx;

	if(busState != SPI_BUS_BUSY_RX)
	{
		SPI_Handle->pRxDataAddr = (uint8_t*)pBuffer;
		SPI_Handle->RxDataSize = (uint16_t)sizeOfData;
		SPI_Handle->busStateRx = SPI_BUS_BUSY_RX;

		if(SPI_Handle->Instance->CR1 & (0x1U << SPI_CR1_DFF))
		{
			SPI_Handle->RxISRFunction = SPI_ReceiveHelper_16Bits;
		}
		else
		{
			SPI_Handle->RxISRFunction = SPI_ReceiveHelper_8Bits;
		}


		SPI_Handle->Instance->CR2 |= (0x1U << SPI_CR2_RXNEIE);
	}




}
/**
 *  @brief SPI_InterruptHandler,
 *
 * 	@param SPI_Handle = User config structure
 *
 *
 * 	@retval Void
 *
 */

void SPI_InterruptHandler(SPI_HandleTypeDef_t *SPI_Handle)
{
	uint8_t interruptSource = 0;
	uint8_t interruptFlag = 0;

	interruptSource = SPI_Handle->Instance->CR2 & (0x1U << SPI_CR2_TXEIE);
	interruptFlag = SPI_Handle->Instance->SR & (0x1U << SPI_SR_TxE);

	if((interruptSource != 0) && (interruptFlag != 0))
	{
		SPI_Handle->TxISRFunction(SPI_Handle);
	}

	interruptSource = SPI_Handle->Instance->CR2 & (0x1U << SPI_CR2_RXNEIE);
	interruptFlag = SPI_Handle->Instance->SR & (0x1U << SPI_SR_RxNE);

	if((interruptSource != 0) && (interruptFlag != 0))
	{
		SPI_Handle->RxISRFunction(SPI_Handle);
	}
}


/**
 *  @brief SPI_ReceiveData ,Receive data from the slave
 *
 * 	@param SPI_Handle = User config structure
 *
 * 	@param pBuffer = Address of data to store the values that ı get
 *
 *	@param sizeOfData = Length of your data in Bytes
 *
 * 	@retval Void
 *
 */

void SPI_ReceiveData(SPI_HandleTypeDef_t *SPI_Handle, uint8_t *pBuffer,uint16_t sizeOfData)
{
	if(SPI_Handle->Init.DFF_Format == SPI_DFF_16BITS)
	{
		while(sizeOfData >0)
		{
			if(SPI_GetFlagStatus(SPI_Handle, SPI_RxNE_FLAG))
			{
				*( (uint16_t*)pBuffer ) = (uint16_t) SPI_Handle->Instance->DR;
				pBuffer += sizeof(uint16_t);
				sizeOfData -= 2;
			}
		}
	}
	else
	{
		while(sizeOfData >0)
		{
			if(SPI_GetFlagStatus(SPI_Handle, SPI_RxNE_FLAG))
			{
				*(pBuffer) =*((__IO uint8_t*)&SPI_Handle->Instance->DR);
				pBuffer += sizeof(uint8_t);
				sizeOfData --;
			}
		}
	}

}



/**
 *  @brief SPI_GetFlagStatus ,return the flag of SR register
 *
 * 	@param SPI_Handle = User config structure
 *
 * 	@param SPI_Flag = Flag name of SR register

 *
 * 	@retval SPI_FlagStatus_t
 *
 */


SPI_FlagStatus_t SPI_GetFlagStatus(SPI_HandleTypeDef_t *SPI_Handle, uint16_t SPI_Flag)
{

	return (SPI_Handle->Instance->SR & SPI_Flag) ? SPI_FLAG_SET : SPI_FLAG_RESET;


}
