#include <stdlib.h>
#include <cmath>
#include <iostream>
#include <string>
#include "BigInt.h"
#include <stdio.h>


using namespace std;


BigInt::BigInt(const BigInt& k){
	size = k.size;
	digit = new unsigned int [size];
	for (unsigned int i=0; i<size ; i++){
		digit [i] = k.digit[i];
	}
}

BigInt::~BigInt(){
	delete [] digit;
}

BigInt::BigInt(int n){
	size = n;
	digit = new unsigned int[n];
	for (int i=0; i<size; i++){
		digit [i] = (unsigned int)0;
	}
}


/*............BASIC OPERATIONS IMPLEMENTATION.......... */

void BigInt::addBigInt(BigInt& a, BigInt& b, BigInt& result)
{
    unsigned long long int base = 0x100000000;
    unsigned int carry=0;
    int bigger = (a.size>b.size)?a.size:b.size;

    for(int i=0;i<bigger;i++)
    {
        //unsigned long long int result = 0;
    	unsigned int res;
        res = (unsigned int) a.digit[i] + (unsigned int) b.digit[i] + carry;
        result.digit[i] = (unsigned int) (res % base);
        carry = (unsigned int) (res / base);
    }
}

void BigInt::subBigInt(BigInt& a, BigInt& b, BigInt& result)
{
    unsigned long long int base = 0x100000000;
    unsigned int carry=0;
    int bigger = (a.size>b.size)?a.size:b.size;

    for(int i=0;i<bigger;i++)
    {

    	unsigned int res;
        res = (unsigned int) a.digit[i] - (unsigned int) b.digit[i] + carry;
        result.digit[i] = (unsigned int) (res % base);
        carry = (unsigned int) (res / base);
    }
}

void BigInt::multiplyBigInt(BigInt& a, BigInt& b, BigInt& result){

	unsigned long long base = 0x100000000;
	unsigned long long product;
	unsigned int last=0;
	int m = a.size / 2 ;

    for(int k=0;k<size;k++)
    {
        result.digit[k] =0;
    }


	for (int j=0; j<m; j++){
		if(b.digit[j]==0){
			result.digit[j+m] = 0;
		}
		else{
			last =0;
			for (int i=0 ; i < m; i++ ){
				product = ((unsigned long long int) a.digit[i]) * ((unsigned long long int) b.digit[j]) + result.digit[i+j]+ last;
				result.digit[i+j] = product % base;
				last = product / base;
			}
		}
	}
}


void BigInt::copyBigInt(BigInt& a, int j){

	int fnzc = a.size; // FirstNonZeroCell
	for (int i=0; i<size; i++){
		if (i >= j && (i-j)<fnzc){
			digit[i] = a.digit[i-j];
		}
		else{
			digit [i] = 0;
		}
	}
}

int compareBigInt(BigInt& a, BigInt& b){

	int result;
	for (int i = a.size; i>= 0 ; i-- ){

		if(a.digit[i] != b.digit[i]){
			if(a.digit[i] > b.digit[i]){
				result = 1;
				break;
			}
			else {
				if (a.digit[i] < b.digit[i]){
					result = -1;
					break;
				}
			}
		}
	}
	return result;
}

///-------- Code Borrowed From Pantho starts-----------------

long long int normalize(unsigned long long int x)
{
   long long int n;
   if (x == 0) return(32);
   n = 0;
   if (x <= 0x00000000FFFFFFFF) {n = n +32; x = x <<32;}
   if (x <= 0x0000FFFFFFFFFFFF) {n = n +16; x = x <<16;}
   if (x <= 0x00FFFFFFFFFFFFFF) {n = n + 8; x = x << 8;}
   if (x <= 0x0FFFFFFFFFFFFFFF) {n = n + 4; x = x << 4;}
   if (x <= 0x3FFFFFFFFFFFFFFF) {n = n + 2; x = x << 2;}
   if (x <= 0x7FFFFFFFFFFFFFFF) {n = n + 1;}
   return n;
}

void BigInt::clearBigInt()
{
    for(int i=(size-1);i>=0;i--)
        digit[i]=0;
}
void BigInt::displayBigInt(){

	int nonZeroDigitFlag =0;
	    for(int i=(size-1);i>=0; i--)
	    {
	        if(digit[i]!=0)
	        {
	            nonZeroDigitFlag=1;
	        }
	        if(nonZeroDigitFlag==1)
	        {
	            printf("%u ",digit[i]);
	        }
	    }

	    if(nonZeroDigitFlag ==0)
	    {
	        printf("0");
	    }
	    cout << endl;
}
int BigInt::msbBigInt()
{
    int msb=0;

    for(int i=(size-1);i>=0;i--)
    {
        if(digit[i]!=0)
        {
            msb=i;
            break;
        }
    }

    return msb;
}


int divideBigInt(BigInt& u, BigInt& v,BigInt& q, BigInt& r)
{
	int flagCompare = compareBigInt(u,v);
	    if(flagCompare==-1)
	    {
	        q.clearBigInt();
	        r.copyBigInt(u,0);

	    }
	    else if(flagCompare ==0)
	    {
	        q.clearBigInt();
	        r.clearBigInt();
	        q.digit[0]=1;

	    }
	    else
	    {


	   int m = u.msbBigInt() +1;
	   int n = v.msbBigInt() +1;
	   unsigned long long int b = 4294967296; // Number base (32 bits).

	   // Normalized form of u, v.
	   unsigned int *unorm = new unsigned int[2*(m + 1)];
	   unsigned int *vnorm = new unsigned int[2*n];
	   // Estimated quotient digit.
	   unsigned long long int qhat;
	   unsigned long long int rhat;
	   // Product of two digits.
	   unsigned long long int p;
	   long long int s, i, j, t, k;



	   if (m < n || n <= 0 || v.digit[n-1] == 0)
	      return 1;              // Return if invalid param.

	   if (n == 1) {                        // Take care of
	      k = 0;                            // the case of a
	      for (j = m - 1; j >= 0; j--) {    // single-digit
	         q.digit[j] = (k*b + u.digit[j])/v.digit[0];      // divisor here.
	         k = (k*b + u.digit[j]) - q.digit[j]*v.digit[0];
	      }
	      r.digit[0] = k;
	      return 0;
	   }

	   s = normalize(v.digit[n-1]) - 32;        // 0 <= s <= 15.
	   //vnorm = (unsigned int *)malloc(2*n);
	   for (i = n - 1; i > 0; i--)
	   vnorm[i] = (v.digit[i] << s) | (v.digit[i-1] >> (32-s));
	   vnorm[0] = v.digit[0] << s;

	   //unorm = (unsigned int *)malloc(2*(m + 1));
	   unorm[m] = u.digit[m-1] >> (32-s);
	   for (i = m - 1; i > 0; i--)
	      unorm[i] = (u.digit[i] << s) | (u.digit[i-1] >> (32-s));
	   unorm[0] = u.digit[0] << s;

	   //step D2, D3 loop
	   for (j = m - n; j >= 0; j--) {
	      qhat = (unorm[j+n]*b + unorm[j+n-1])/vnorm[n-1];
	      rhat = (unorm[j+n]*b + unorm[j+n-1]) - qhat*vnorm[n-1];
	again:
	      if (qhat >= b || qhat*vnorm[n-2] > b*rhat + unorm[j+n-2])
	      { qhat = qhat - 1;
	        rhat = rhat + vnorm[n-1];
	        if (rhat < b) goto again;
	      }

	      // D4 Multiply and subtract.
	      k = 0;
	      for (i = 0; i < n; i++) {
	         p = qhat*vnorm[i];
	         t = unorm[i+j] - k - (p & 0xFFFFFFFF);
	         unorm[i+j] = t;
	         k = (p >> 32) - (t >> 32);
	      }
	      t = unorm[j+n] - k;
	      unorm[j+n] = t;

	      q.digit[j] = qhat;              // Store quotient digit.
	      if (t < 0) {              // If we subtracted too
	         q.digit[j] = q.digit[j] - 1;       // much, add back.
	         k = 0;
	         for (i = 0; i < n; i++) {
	            t = unorm[i+j] + vnorm[i] + k;
	            unorm[i+j] = t;
	            k = t >> 32;
	         }
	         unorm[j+n] = unorm[j+n] + k;
	      }
	   } // End j.

	      for (i = 0; i < n; i++)
	         r.digit[i] = (unorm[i] >> s) | (unorm[i+1] << (32-s));

	   return 0;

	    }

}


void BigInt::expoModNBigInt(BigInt& x, BigInt& y, BigInt& N, BigInt& result)
{

	if (y.msbBigInt() == 0 && y.digit[0] ==0)
		{
			result.digit[0] = 1;
			for (int i = 1; i < result.size; i++)
			{
				result.digit[i] = 0;
			}
		}
		else
		{
			BigInt temp(size);
			BigInt reminder(size);
			BigInt q(size);
			BigInt tempresult(size);
			BigInt tempprod(size), prod(size);
			BigInt tempx(size), tempprod1(size);

			BigInt value2(size);
			value2.digit[0]=2;

			divideBigInt(y,value2, q, reminder);
			temp.copyBigInt(q, 0);
			expoModNBigInt(x, temp,N, tempprod);

			prod.multiplyBigInt(tempprod, tempprod, tempresult);

			temp.copyBigInt(tempresult, 0);

			if (y.digit[0] % 2 != 0)
			{
				tempprod1.multiplyBigInt(temp, x, tempx);
				temp.copyBigInt(tempx, 0);
			}
			BigInt q1(size), r(size);
			divideBigInt(temp, N,q1,r);
			result.copyBigInt(r,0);
		}

		return;

}

//----------- Code Borrowed From Pantho Ends here---------------/

void BigInt::gcdBigInt(BigInt& a, BigInt& b, BigInt& result){

	BigInt n(a.size);
	BigInt m(b.size);
	n.copyBigInt(a,0);
	b.copyBigInt(b,0);
	if (b.msbBigInt()== 0 && b.digit[0] == 0){
		for (int i=0; i<result.size; i++){
			result.digit[i] = a.digit[i];
		}
	}
	else{
		BigInt q(a.size);
		BigInt r(a.size);
		divideBigInt(a,b,q,r);
		gcdBigInt(b,r,result);
	}
}

void BigInt::randBigInt(int n)
{
    for(int i=0;i<n;i++)
    {
        unsigned int rnd = (unsigned int)(rand());
        digit[i] = rnd;
    }
}

/*
bool BigInt::primeBigInt(BigInt& a, int k){

	BigInt n(a.size);
	BigInt b(a.size);
	BigInt c(a.size);
	c.digit[0] = 2;
	BigInt d(a.size);
	d.digit[0] = 4;
	BigInt e(a.size);
	e.digit[0]= 1;
	BigInt tempa(a.size);
	BigInt sum(a.size);

	//Check some corner cases

	n.copyBigInt(a,0);
	if ((n.msbBigInt()== 0 && n.digit[0] == 0) ||( n.msbBigInt()==0 && n.digit[0]==4) ) return false;
	if (n.msbBigInt()== 0 && n.digit[0] == 3) return true;

	while (k > 0){
		BigInt rand(a.size);
		BigInt diff(a.size);
		BigInt tempdiff(a.size);
		diff.subBigInt(n,d,tempdiff); //n-4
		rand= randBigInt(2)%tempdiff; // rand()%(N-4)
		tempa.addBigInt(c, rand, sum); // 2+rand()%(n-4)
		BigInt fermat(a.size);
		BigInt tempfermat(a.size);
		BigInt tempb(a.size);
		BigInt temp(a.size);
		BigInt result(a.size);
		temp.subBigInt(a,e,tempb); // n-1
		tempfermat.expoModNBigInt(sum,tempb,n,result); // Fermat Little Theorem.
		if (result.msbBigInt() == 0 && result.digit[0]!=1) return false;
		k --;
	}
	return true;
}
*/

/*............BASIC OPERATIONS IMPLEMENTATION ENDS.......... */

/*............RSA ALGORITHM IMPLEMENTATION..................*/

//GENERATE PHI
//INPUT: P, Q
//OUTPUT: PHI
void BigInt::generatePhiBigInt(BigInt& a, BigInt& b, BigInt& result){

	BigInt p(a.size);
	BigInt q(b.size);
	BigInt c(a.size);
	c.digit[0] = 1;
	BigInt tempP(a.size);
	BigInt tempQ(b.size);
	BigInt tempResult(a.size);

	p.subBigInt(a,c,tempP);
	q.subBigInt(b,c, tempQ);
	tempResult.multiplyBigInt(tempP,tempQ,result);
}
//GENERATE E
//INPUT: PHI
//OUTPUT: E
void BigInt::generateEBigInt(BigInt& a, BigInt& result){

	BigInt e(a.size),e1(a.size), tempe(a.size), gcd(a.size), tempgcd(a.size), encreaseby(a.size);
	e.digit[0]=3;
	encreaseby.digit[0]=2;

	while(1){
		tempgcd.gcdBigInt(a,e, gcd);
		if (gcd.msbBigInt()==0 && gcd.digit[0] == 1){
			break;
		}
		tempe.addBigInt(e,encreaseby,e1);
		e.copyBigInt(e1,0);
	}
		result.copyBigInt(e,0);
}
//GENERATE D
//INPUT: E, PHI
//OUTPUT:D
void BigInt::generateDBigInt(BigInt& e, BigInt& phi,BigInt& result){

	BigInt prod(e.size), tempprod(e.size), q(e.size),tempq(e.size), r(e.size) ;
	BigInt n(e.size), encrementby(e.size), sum(e.size), tempsum(e.size);
	n.digit[0] = 1;
	int i = 0;
	while(1){
		i++;
		encrementby.digit[0]=i;
		tempprod.multiplyBigInt(encrementby, phi, prod);
		tempsum.addBigInt(prod,n,sum);
		divideBigInt(sum,e,q,r);
		if(r.msbBigInt()==0 && r.digit[0]==0){
			result.copyBigInt(q,0);
			break;
		}
	}
}

void BigInt::RSABigInt (int flag, BigInt& input, BigInt& result){

	BigInt p(input.size), q(input.size);
	BigInt N(input.size), tempN(input.size);
	BigInt Phi(input.size),tempPhi(input.size);
	BigInt e(input.size), tempe(input.size);
	BigInt d(input.size), tempd(input.size);
	BigInt tempresult(input.size), tempresult1(input.size);
	p.digit[0]=961748941;
	q.digit[0]=961749443;

	multiplyBigInt(p,q,N); //generate N
	generatePhiBigInt(p,q,Phi); //generate PHI
	generateEBigInt(Phi,e);


	if(flag == 1){
		expoModNBigInt(input,e,N,result); //Encrypt
	}
	else if (flag == 0){
		generateDBigInt(e,Phi,d); //generate D
		expoModNBigInt(input,d,N,result);
	}

}


