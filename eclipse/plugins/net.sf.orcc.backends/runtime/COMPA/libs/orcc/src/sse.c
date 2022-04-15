/*
 * Copyright (c) 2014, EPFL
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *   * Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright notice,
 *     this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 *   * Neither the name of the EPFL nor the names of its
 *     contributors may be used to endorse or promote products derived from this
 *     software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */
 
 
/**
 * Optimized procedures (SSE).
 * 
 * @author Daniele Renzi (EPFL) <daniele.renzi@epfl.ch>
 */

#include <stdio.h>
#include <stdlib.h>

#include "sse.h"

#include "emmintrin.h"


/***********************************************************************************************************************************
 SelectCu 
 ***********************************************************************************************************************************/

#define SCU_SIZE_DIV16(H) (H >> 4)
#define SCU_SIZE_MOD16(H) (H & 0x0F)

// copy 8-bits elements into a 8-bits array, for H elements
#define COPY_8_8(H, J, K)                                                                                                              \
void copy_8_8_ ## H ## _ ## J ## x ## K ## _orcc(                                                                                      \
  u8 outputSample[J * K],                                                                                                              \
  u8 inputSample[H],                                                                                                                   \
  u32 idxBlkStride)                                                                                                                    \
{                                                                                                                                      \
  int i = 0;                                                                                                                           \
  __m128i * pm128iInputSample = (__m128i *) &inputSample[0];                                                                           \
  __m128i * pm128iOutputSample = (__m128i *) &outputSample[idxBlkStride + 0];                                                          \
  __m128i m128iInputSample;                                                                                                            \
                                                                                                                                       \
  i = 0;                                                                                                                               \
  for (i = 0; i < SCU_SIZE_DIV16(H); i++)                                                                                              \
  {                                                                                                                                    \
    m128iInputSample = _mm_loadu_si128(pm128iInputSample + i);                                                                         \
    _mm_storeu_si128(pm128iOutputSample + i, m128iInputSample);                                                                        \
  }                                                                                                                                    \
                                                                                                                                       \
  if (SCU_SIZE_MOD16(H) == 8)                                                                                                                \
  {                                                                                                                                    \
    pm128iOutputSample = (__m128i *) &outputSample[H - 8];                                                                             \
    pm128iInputSample = (__m128i *) &inputSample[H - 8];                                                                               \
    m128iInputSample = _mm_loadl_epi64(pm128iInputSample);                                                                             \
    _mm_storel_epi64(pm128iOutputSample, m128iInputSample);                                                                            \
  }                                                                                                                                    \
}

// Declare more functions if needed
COPY_8_8(16, 64, 64)
COPY_8_8(16, 32, 32)


// add 8-bits elements to 16-bits elements and clip, for H elements. First array (pred) is K * J.
#define ADD_8_16_CLIP(H, K, J)                                                                                                         \
void add_8_16_clip_ ## H ## _ ## K ## x ## J ## _orcc(                                                                                 \
  u8 predSample[K * J],                                                                                                                \
  i16 resSample[H],                                                                                                                    \
  u8 Sample[H],                                                                                                                        \
  u16 idxBlkStride)                                                                                                                    \
{                                                                                                                                      \
  int i = 0;                                                                                                                           \
                                                                                                                                       \
  __m128i * pm128iPredSamp = (__m128i *) &predSample[idxBlkStride + 0];                                                                \
  __m128i m128itmp_predSamp;                                                                                                           \
  __m128i * pm128iResSample = (__m128i *) &resSample[0];                                                                               \
  __m128i m128itmp_ResidualSample;                                                                                                     \
  __m128i m128itmp_add_i16_0, m128itmp_add_i16_1;                                                                                      \
  __m128i * pm128iSample = (__m128i *) &Sample[0];                                                                                     \
  __m128i m128iZero = _mm_set1_epi16(0);                                                                                               \
                                                                                                                                       \
  for (i = 0; i < SCU_SIZE_DIV16(H); i++)                                                                                              \
  {                                                                                                                                    \
    m128itmp_predSamp =                                                                                                                \
      _mm_unpacklo_epi8(                                                                                                               \
      _mm_loadu_si128(pm128iPredSamp + i),                                                                                             \
      m128iZero);                                                                                                                      \
    m128itmp_ResidualSample = _mm_loadu_si128(pm128iResSample + (i << 1));                                                             \
    m128itmp_add_i16_0 = _mm_add_epi16(m128itmp_predSamp, m128itmp_ResidualSample);                                                    \
                                                                                                                                       \
    m128itmp_predSamp =                                                                                                                \
      _mm_unpackhi_epi8(                                                                                                               \
      _mm_loadu_si128(pm128iPredSamp + i),                                                                                             \
      m128iZero);                                                                                                                      \
    m128itmp_ResidualSample = _mm_loadu_si128(pm128iResSample + (i << 1) + 1);                                                         \
    m128itmp_add_i16_1 = _mm_add_epi16(m128itmp_predSamp, m128itmp_ResidualSample);                                                    \
                                                                                                                                       \
    _mm_storeu_si128(pm128iSample + i, _mm_packus_epi16(m128itmp_add_i16_0, m128itmp_add_i16_1));                                      \
  }                                                                                                                                    \
                                                                                                                                       \
  if (SCU_SIZE_MOD16(H) == 8)                                                                                                                \
  {                                                                                                                                    \
    m128itmp_predSamp =                                                                                                                \
      _mm_unpacklo_epi8(                                                                                                               \
      _mm_loadl_epi64(pm128iPredSamp + i),                                                                                             \
      m128iZero);                                                                                                                      \
    m128itmp_ResidualSample = _mm_loadu_si128(pm128iResSample + (i << 1));                                                             \
    m128itmp_add_i16_0 = _mm_add_epi16(m128itmp_predSamp, m128itmp_ResidualSample);                                                    \
                                                                                                                                       \
    m128itmp_add_i16_1 = _mm_set1_epi16(0);                                                                                            \
                                                                                                                                       \
    _mm_storel_epi64(pm128iSample + i, _mm_packus_epi16(m128itmp_add_i16_0, m128itmp_add_i16_1));                                      \
  }                                                                                                                                    \
}

// Declare more functions if needed
ADD_8_16_CLIP(  16,  1, 16)
ADD_8_16_CLIP(   8, 64, 64)

ADD_8_16_CLIP(  16, 64, 64)
ADD_8_16_CLIP(  32, 64, 64)
ADD_8_16_CLIP(  64, 64, 64)
ADD_8_16_CLIP( 256, 64, 64)

ADD_8_16_CLIP(1024, 64, 64)

ADD_8_16_CLIP(  16, 32, 32)
ADD_8_16_CLIP(  64, 32, 32)
ADD_8_16_CLIP( 256, 32, 32)

static i32 clip_i32(i32 Value, i32 minVal, i32 maxVal) {
	i32 tmp_if;

	if (Value > maxVal) {
		tmp_if = maxVal;
	} else {
		if (Value < minVal) {
			tmp_if = minVal;
		} else {
			tmp_if = Value;
		}
	}
	return tmp_if;
}

// For shared_memory
void addClip_orcc(
  u16 blkAddr[2],
  u16 blkAddrChr[2],
  u16 blkAddrRes[2],
  u16 blkAddrResChr[2],
  u32 intraIdx,
  u32 idxRes,
  u8 dbfIdx,
  u8 numBlkSide,
  i16 puAddr[2],
  i16 puAddrChr[2],
  u16 tuAddr[2],
  u16 tuAddrChr[2],
  u8 dbfPict[2][3][4096][2048],
  u8 lumaPred[1024][64][64],
  u8 chromaPred[1024][2][32][32],
  i16 residual[8192][6144])
{
  u32 xOffDbf = puAddr[0] + blkAddr[0];
  u32 yOffDbf = puAddr[1] + blkAddr[1];
  u32 xOffLumaPred = tuAddr[0] + blkAddr[0];
  u32 yOffLumaPred = tuAddr[1] + blkAddr[1];
  u32 offRes = blkAddrRes[0] * 64 + blkAddrRes[1];

  u32 xOffChrDbf = puAddrChr[0] + blkAddrChr[0];
  u32 yOffChrDbf = puAddrChr[1] + blkAddrChr[1];
  u32 xOffChrLumaPred = tuAddrChr[0] + blkAddrChr[0];
  u32 yOffChrLumaPred = tuAddrChr[1] + blkAddrChr[1];
  u32 offChrRes[3];
  int x, y;
  u32 compIdx = 0;

  offChrRes[0] = 0;
  offChrRes[1] = 64*64 + blkAddrResChr[0] * 32 + blkAddrResChr[1];
  offChrRes[2] = 64*64 + 32*32 + blkAddrResChr[0] * 32 + blkAddrResChr[1];

  switch (numBlkSide)
  {
    case 1:
    {
      for (x = 0; x < 4 * 1; x++)
      {
        for (y = 0; y < 4 * 1; y++)
    	{
    	  dbfPict[dbfIdx][0][xOffDbf + x][yOffDbf + y] =
    	    clip_i32(lumaPred[intraIdx][xOffLumaPred + x][yOffLumaPred + y] +
            residual[idxRes][offRes + x * 64 + y], 0, 255);
        }
      }
      for (compIdx = 1; compIdx <= 2; compIdx++)
      {
        for (x = 0; x < 2 * 1; x++)
        {
          for (y = 0; y < 2 * 1; y++)
          {
            dbfPict[dbfIdx][compIdx][xOffChrDbf + x][yOffChrDbf + y] =
              clip_i32(chromaPred[intraIdx][compIdx-1][xOffChrLumaPred + x]
                [yOffChrLumaPred + y] + residual[idxRes][offChrRes[compIdx] +
                x * 32 + y], 0, 255);
          }
        }
      }
      break;
    }
    case 2:
      {
        for (x = 0; x < 4 * 2; x++)
        {
          add_8_16_clip_8_64x64_orcc(
            &lumaPred[intraIdx][xOffLumaPred + x][yOffLumaPred],
            &residual[idxRes][offRes + x * 64 + 0],
            &dbfPict[dbfIdx][0][xOffDbf + x][yOffDbf + 0],
            0);
        }
        for (compIdx = 1; compIdx <= 2; compIdx++)
        {
          for (x = 0; x < 2 * 2; x++)
          {
            for (y = 0; y < 2 * 2; y++)
            {
              dbfPict[dbfIdx][compIdx][xOffChrDbf + x][yOffChrDbf + y] =
                clip_i32(chromaPred[intraIdx][compIdx-1][xOffChrLumaPred + x]
                  [yOffChrLumaPred + y] + residual[idxRes][offChrRes[compIdx] +
                  x * 32 + y], 0, 255);
            }
          }
        }
        break;
      }
    case 4:
      {
        for (x = 0; x < 4 * 4; x++)
        {
          add_8_16_clip_16_64x64_orcc(
            &lumaPred[intraIdx][xOffLumaPred + x][yOffLumaPred],
            &residual[idxRes][offRes + x * 64 + 0],
            &dbfPict[dbfIdx][0][xOffDbf + x][yOffDbf + 0],
            0);
        }
        for (compIdx = 1; compIdx <= 2; compIdx++)
        {
          for (x = 0; x < 2 * 4; x++)
          {
            add_8_16_clip_8_64x64_orcc(
              &chromaPred[intraIdx][compIdx - 1][xOffChrLumaPred + x][yOffChrLumaPred],
              &residual[idxRes][offChrRes[compIdx] + x * 32 + 0],
              &dbfPict[dbfIdx][compIdx][xOffChrDbf + x][yOffChrDbf + 0],
              0);
          }
        }
        break;
      }
    case 8:
      {
        for (x = 0; x < 4 * 8; x++)
        {
          add_8_16_clip_32_64x64_orcc(
            &lumaPred[intraIdx][xOffLumaPred + x][yOffLumaPred],
            &residual[idxRes][offRes + x * 64 + 0],
            &dbfPict[dbfIdx][0][xOffDbf + x][yOffDbf + 0],
            0);
        }
        for (compIdx = 1; compIdx <= 2; compIdx++)
        {
          for (x = 0; x < 2 * 8; x++)
          {
            add_8_16_clip_16_64x64_orcc(
              &chromaPred[intraIdx][compIdx - 1][xOffChrLumaPred + x][yOffChrLumaPred],
              &residual[idxRes][offChrRes[compIdx] + x * 32 + 0],
              &dbfPict[dbfIdx][compIdx][xOffChrDbf + x][yOffChrDbf + 0],
              0);
          }
        }
        break;
      }
	default:
	  break;
  }
}

/***********************************************************************************************************************************
 DecodingPictureBuffer 
 ***********************************************************************************************************************************/

void fillBorder_luma_orcc(
	u8 pictureBuffer[17][2304][4352],
	i8 lastIdx,
	int xSize,
	int ySize,
	u16 border_size)
{
  int y, x;
  u8 tmp_pictureBuffer;
  u8 tmp_pictureBuffer0;

  __m128i * __restrict pm128iPictureBuffer;
  __m128i * __restrict pm128iPictureBuffer0;
  __m128i * __restrict pm128iPictureBuffer1;
  __m128i * __restrict pm128iPictureBuffer2;
  __m128i m128iWord, m128iWord0;

  int iLoopCount = (xSize >> 4) - 1;

  y = 0;
  while (y <= border_size - 1) {
    pm128iPictureBuffer1 = (__m128i *) &pictureBuffer[lastIdx][border_size][border_size];
    pm128iPictureBuffer2 = (__m128i *) &pictureBuffer[lastIdx][ySize + border_size - 1][border_size];
    pm128iPictureBuffer  = (__m128i *) &pictureBuffer[lastIdx][y][border_size];
    pm128iPictureBuffer0 = (__m128i *) &pictureBuffer[lastIdx][y + ySize + border_size][border_size];
    x = 0;
    while (x <= iLoopCount) {
      m128iWord = _mm_loadu_si128(pm128iPictureBuffer1);
      m128iWord0 = _mm_loadu_si128(pm128iPictureBuffer2);
      _mm_storeu_si128(pm128iPictureBuffer, m128iWord);
      _mm_storeu_si128(pm128iPictureBuffer0, m128iWord0);
      pm128iPictureBuffer1++;
      pm128iPictureBuffer2++;
      pm128iPictureBuffer++;
      pm128iPictureBuffer0++;
      x = x + 1;
    }
    y = y + 1;
  }

  iLoopCount = (border_size >> 4) - 1;
  y = 0;
  while (y <= ySize + 2 * border_size - 1) {
	tmp_pictureBuffer = pictureBuffer[lastIdx][y][border_size];
	tmp_pictureBuffer0 = pictureBuffer[lastIdx][y][xSize + border_size - 1];
	pm128iPictureBuffer = (__m128i *) &pictureBuffer[lastIdx][y][0];
	pm128iPictureBuffer0 = (__m128i *) &pictureBuffer[lastIdx][y][0 + xSize + border_size];
    m128iWord = _mm_set1_epi8(tmp_pictureBuffer);
    m128iWord0 = _mm_set1_epi8(tmp_pictureBuffer0);
    x = 0;
    while (x <= iLoopCount) {
      _mm_storeu_si128(pm128iPictureBuffer, m128iWord);
      _mm_storeu_si128(pm128iPictureBuffer0, m128iWord0);
      pm128iPictureBuffer++;
      pm128iPictureBuffer0++;
      x = x + 1;
    }
    y = y + 1;
  }
}


void fillBorder_chroma_orcc(
	u8 pictureBuffer[17][1280][2304],
	i8 lastIdx,
	int xSize,
	int ySize,
	u16 border_size)
{
  int y, x;
  u8 tmp_pictureBuffer;
  u8 tmp_pictureBuffer0;

  __m128i * __restrict pm128iPictureBuffer;
  __m128i * __restrict pm128iPictureBuffer0;
  __m128i * __restrict pm128iPictureBuffer1;
  __m128i * __restrict pm128iPictureBuffer2;
  __m128i m128iWord, m128iWord0;

  int iLoopCount = (xSize >> 4) - 1;

  y = 0;
  while (y <= border_size - 1) {
    pm128iPictureBuffer1 = (__m128i *) &pictureBuffer[lastIdx][border_size][border_size];
    pm128iPictureBuffer2 = (__m128i *) &pictureBuffer[lastIdx][ySize + border_size - 1][border_size];
    pm128iPictureBuffer  = (__m128i *) &pictureBuffer[lastIdx][y][border_size];
    pm128iPictureBuffer0 = (__m128i *) &pictureBuffer[lastIdx][y + ySize + border_size][border_size];
    x = 0;
    while (x <= iLoopCount) {
      m128iWord = _mm_loadu_si128(pm128iPictureBuffer1);
      m128iWord0 = _mm_loadu_si128(pm128iPictureBuffer2);
      _mm_storeu_si128(pm128iPictureBuffer, m128iWord);
      _mm_storeu_si128(pm128iPictureBuffer0, m128iWord0);
      pm128iPictureBuffer1++;
      pm128iPictureBuffer2++;
      pm128iPictureBuffer++;
      pm128iPictureBuffer0++;
      x = x + 1;
    }
    y = y + 1;
  }

  iLoopCount = (border_size >> 4) - 1;
  y = 0;
  while (y <= ySize + 2 * border_size - 1) {
    tmp_pictureBuffer = pictureBuffer[lastIdx][y][border_size];
    tmp_pictureBuffer0 = pictureBuffer[lastIdx][y][xSize + border_size - 1];
    pm128iPictureBuffer = (__m128i *) &pictureBuffer[lastIdx][y][0];
    pm128iPictureBuffer0 = (__m128i *) &pictureBuffer[lastIdx][y][0 + xSize + border_size];
    m128iWord = _mm_set1_epi8(tmp_pictureBuffer);
    m128iWord0 = _mm_set1_epi8(tmp_pictureBuffer0);
    x = 0;
    while (x <= iLoopCount) {
      _mm_storeu_si128(pm128iPictureBuffer, m128iWord);
      _mm_storeu_si128(pm128iPictureBuffer0, m128iWord0);
      pm128iPictureBuffer++;
      pm128iPictureBuffer0++;
      x = x + 1;
    }
    y = y + 1;
  }
}
