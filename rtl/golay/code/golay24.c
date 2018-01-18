// ------------------------------------------------------------------------
//  File: golay24.c
//
//  An arithmetic decoder for the (24,12,8) Golay code.
//  Note: The C code below assumes execution in a 16-bit computer.
//  Inspired by Stephen Wicker's book, pp. 143-144.
// ------------------------------------------------------------------------
// This program is complementary material for the book:
//
// R.H. Morelos-Zaragoza, The Art of Error Correcting Coding, Wiley, 2002.
//
// ISBN 0471 49581 6
//
// This and other programs are available at http://the-art-of-ecc.com
//
// You may use this program for academic and personal purposes only.
// If this program is used to perform simulations whose results are
// published in a journal or book, please refer to the book above.
//
// The use of this program in a commercial product requires explicit
// written permission from the author. The author is not responsible or
// liable for damage or loss that may be caused by the use of this program.
//
// Copyright (c) 2002. Robert H. Morelos-Zaragoza. All rights reserved.
// ------------------------------------------------------------------------

#include <stdio.h>
#include <math.h>

main()
 {
   /* Array x contains the twelve rows (columns) of the identity matrix */
   int x[12] = { 0x800, 0x400, 0x200, 0x100, 0x080, 0x040,
		 0x020, 0x010, 0x008, 0x004, 0x002, 0x001 };

   /* Array y contains the twelve rows (columns) of the parity-check matrix */
   int y[12] = { 0x7ff, 0xee2, 0xdc5, 0xb8b, 0xf16, 0xe2d,
		 0xc5b, 0x8b7, 0x96e, 0xadc, 0xdb8, 0xb71 };

   int c[2];          /* Codeword composed of 12-bit info and 12-bit parity */
   int r[2];          /* Received vector in two halfs of 12 bits each */
   int e[2];          /* Estimated error vector */

   int s;             /* syndrome */
   int q;             /* modified syndrome */
   int c_hat[2];      /* Estimated codeword */

   int i,j;
   int aux, found;
   int weight(int vector);

   long seed;

   /* -------------- Random generation of a codeword ----------------- */
   time(&seed);
   srandom(seed);
   //c[0] = random()&0xfff;
   c[0] = 0xe06;
   c[1] = 0;
   for (i=0; i<12; i++)
     {
       aux = 0;
       for (j=0; j<12; j++) {
	    aux = aux ^ ( (c[0]&y[i])>>j & 0x01);
         //printf("%d ",(y[i]>>j) & 0x01);
         //if((y[i]>>j) & 0x01 == 1)
         //        printf("%d ",j);
       }
       //printf("\n");
       c[1] = (c[1] << 1) ^ aux;
     }
   printf("c =%3x%3x\n", c[0], c[1]);

   /* --------------------- Introduce errors ------------------------- */
   //e[0] = random()&0x500;
   //e[1] = random()&0x111;
   printf("e =%3x%3x, w(e) = %d\n", e[0], e[1], weight(e[0])+weight(e[1]));

   /* ---------------------- Received word --------------------------- */
   //r[0] = c[0]^e[0];
   //r[1] = c[1]^e[1];
   r[0] = 0xe22;
   r[1] = 0x23e;

   /******* STEP 1: Compute the syndrome of the received vector ********/
   s = 0;
   for (j=0; j<12; j++)
     {
       aux = 0;
       for (i=0; i<12; i++) {
	      aux = aux ^ ( (x[j]&r[0])>>i &0x01 ); /* identity part */
         //printf("%d ",(x[j]>>(11 - i)) & 0x01);
         //if ((x[j]>>i) & 0x01 == 1)
         //        printf("%d ",12 + i);
       }
       for (i=0; i<12; i++) {
	      aux = aux ^ ( (y[j]&r[1])>>i &0x01 ); /* parity part */
         //printf("%d ",(y[j]>>(11 -i)) & 0x01);
         //if ((y[j]>> i) & 0x01 == 1)
         //          printf("%d ", i);
       }
       //printf(" \t\t %x %x -- %x %x ",x[j], r[0], y[j],r[1]);
       //printf("\n");
       s = (s<<1)^aux;
       //printf("\t\t %x %x \n",aux,s);
     }
   printf("r =%3x%3x, s = %x, w(s) = %d\n", r[0], r[1], s, weight(s));

   /******* STEP 2 */
   printf("Step 2\n");
   if (weight(s)<=3)
     {
       e[0] = s;
       e[1] = 0;
     }
   else
     {
       /******* STEP 3 */
       printf("Step 3\n");
       i = 0;
       found = 0;
       do {
           printf("s^y[%d] = %x weigth = %d \n",i,s^y[i],weight(s^y[i]));
            if (weight(s^y[i]) <=2)
              {
                e[0] = s^y[i];
                e[1] = x[i];
                found = 1;
              }
            i++;
       } while ( (i<12) && (!found) );

       if (( i==12 ) && (!found))
	 {
	   /******* STEP 4 */
	   printf("Step 4\n");
	   q = 0;
	   for (j=0; j<12; j++)
	     {
	       aux = 0;
	       for (i=0; i<12; i++)
		 aux = aux ^ ( (y[j]&s)>>i & 0x01 );
	       q = (q<<1) ^ aux;
	     }
      printf("syn_err = %x\n",q);
	   /******* STEP 5 */
	   printf("Step 5\n");
	   if (weight(q) <=3)
	     {
	       e[0] = 0;
	       e[1] = q;
	     }
	   else
	     {
	       /******* STEP 6 */
	       printf("Step 6\n");
	       i = 0;
	       found = 0;
	       do {
           printf("q^y[%d] = %x weigth = %d \n",i,q^y[i],weight(q^y[i]));
		 if (weight(q^y[i]) <=2)
		   {
		     e[0] = x[i];
		     e[1] = q^y[i];
		     found = 1;
		   }
		 i++;
	       } while ( (i<12) && (!found) );

	       if ((i==12) && (!found))
		 {
		   /******* STEP 7 */
		   printf("uncorrectable error pattern\n");
		   /* You can raise a flag here, or output the vector as is */
		   exit(1);
		 }
	     }
	 }
     }

   /* ------------------- Correct received word --------------------- */
   c_hat[0] = r[0]^e[0];
   c_hat[1] = r[1]^e[1];
   printf("Estimated codeword =%x%x\n", c_hat[0], c_hat[1]);
 }

/* Function to compute the Hamming weight of a 12-bit integer */
int weight(int vector)
 {
   int i, aux;
   aux = 0;
   for (i=0; i<12; i++)
     if ( (vector>>i)&1 )
       aux++;
   return(aux);
 }

