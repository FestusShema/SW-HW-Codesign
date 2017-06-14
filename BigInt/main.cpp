#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <exception>
#include <string>
#include <memory>
#include "BigInt.h"
#include <time.h>

using std::cout;
using std::string;
using namespace std;

#define size 2048

/*TESTING BASIC OPERATIONS*/

///*
void BasicOps(){
	BigInt a(size);
	BigInt b(size);
	BigInt c(size);
	BigInt sum(size);
	BigInt randa(size);
	BigInt randb(size);

	//Test Random Generator
	randa.randBigInt(size);
	//cout<<"rand a :\n";
    //randa.displayBigInt();
	randb.randBigInt(size);
	//cout<<"rand b :\n";
   // randb.displayBigInt();
	//cout<<"a :\n";
   // a.displayBigInt();
	//ADD

	struct timespec tstart={0,0}, tend={0,0};
	clock_gettime(CLOCK_MONOTONIC, &tstart);
	a.addBigInt(randa,randb, sum);
	clock_gettime(CLOCK_MONOTONIC, &tend);
	printf("Addition took about %.5f seconds\n",
	((double)tend.tv_sec + 1.0e-9*tend.tv_nsec) -
	((double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec));

	//cout<<"sum :\n";
	//sum.displayBigInt();

    //SUB
	tstart={0,0}, tend={0,0};
	clock_gettime(CLOCK_MONOTONIC, &tstart);
	a.subBigInt(sum, randa, b);
	clock_gettime(CLOCK_MONOTONIC, &tend);
	printf("SUB took about %.5f seconds\n",
    ((double)tend.tv_sec + 1.0e-9*tend.tv_nsec) -
	((double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec));

	//cout<<"b\n";
	//b.displayBigInt();

	//MULT
	tstart={0,0}, tend={0,0};
	clock_gettime(CLOCK_MONOTONIC, &tstart);
	a.multiplyBigInt(randa, randb, c);
	clock_gettime(CLOCK_MONOTONIC, &tend);
	printf("MULT took about %.5f seconds\n",
	((double)tend.tv_sec + 1.0e-9*tend.tv_nsec) -
	((double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec));

	//cout<<"multi=\n";
	//c.displayBigInt();
   //DIVIDE
	BigInt q(size);
	BigInt r(size);

	tstart={0,0}, tend={0,0};
	clock_gettime(CLOCK_MONOTONIC, &tstart);
	divideBigInt(c, randa, q, r);
	clock_gettime(CLOCK_MONOTONIC, &tend);
	printf("DIV took about %.5f seconds\n",
	((double)tend.tv_sec + 1.0e-9*tend.tv_nsec) -
	((double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec));

	//cout<< "divide: ";
	//q.displayBigInt();
	//cout<<"remainder: ";
	//r.displayBigInt();

	//GCD
	BigInt num1(size);
	num1.digit[0]= 982445323;
	BigInt num2(size);
	num2.digit[0]= 982445729;
	BigInt gcd(size);

	tstart={0,0}, tend={0,0};
	clock_gettime(CLOCK_MONOTONIC, &tstart);
	a.gcdBigInt(randa, randb, gcd);
	clock_gettime(CLOCK_MONOTONIC, &tend);
	printf("GCD took about %.5f seconds\n",
	((double)tend.tv_sec + 1.0e-9*tend.tv_nsec) -
	((double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec));

	//cout<<"gcd= ";
	//gcd.displayBigInt();


}
//*/

/*TESTING RSA OPERATION*/

void testRSA(){
	BigInt a(size);
	a.digit[0]= 200000000;
	cout<<"Original PlainText =: ";
	a.displayBigInt();
	BigInt tempN(size), tempp(size), tempq(size), tempPhi(size), Phi(size),e(size), tempe(size);
	BigInt result(size), tempresult(size), d(size), tempd(size), result1(size), tempresult1(size);

/*MANUALLY TESTING RSA OPERATIONS*/
/*
    e.digit[0]=3;
	N.digit[0]=215359519 ; N.digit[1]= 145164097;
    BigInt p(size), q(size), N(size);
	p.digit[0]= 11;
	q.digit[0]= 3;
	cout<<"Original PlainText =: ";
	a.displayBigInt();
	tempN.multiplyBigInt(p,q,N);
	cout<<"N= "<<endl;
	N.displayBigInt();
	tempPhi.generatePhiBigInt(p,q,Phi);
	cout<<"Phi= "<<endl;
	Phi.displayBigInt();
	tempe.generateEBigInt(Phi,e);
	cout<<"E= "<<endl;
	e.displayBigInt();
	tempd.generateDBigInt(e,Phi,d); //generate D
	cout<<"D= "<<endl;
	d.displayBigInt();
	tempresult.expoModNBigInt(a,e,N,result); // a^e mod N = result
	cout<<"CipherText= "<<endl;
	result.displayBigInt();
	tempresult1.expoModNBigInt(result,d,N,result1);
	cout<<"PlainText= "<<endl;
	result1.displayBigInt();
*/

/*AUTOMATED RSA OPERATION*/

	struct timespec tstart={0,0}, tend={0,0};
	clock_gettime(CLOCK_MONOTONIC, &tstart);

	int flag = 1;
	tempresult.RSABigInt(flag, a,result);
	cout<<"CipherText =: ";
	result.displayBigInt();

	clock_gettime(CLOCK_MONOTONIC, &tend);
		printf("Encryption took about %.5f seconds\n",
	    ((double)tend.tv_sec + 1.0e-9*tend.tv_nsec) -
		((double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec));

	BigInt CipherText(size);
	CipherText.copyBigInt(result,0);

	tstart={0,0}, tend={0,0};
	clock_gettime(CLOCK_MONOTONIC, &tstart);

	flag = 0;
	tempresult.RSABigInt(flag, CipherText,result1);
	cout<<"Deciphered Text =: ";
	result1.displayBigInt();

	clock_gettime(CLOCK_MONOTONIC, &tend);
		printf("Decryption took about %.5f seconds\n",
		((double)tend.tv_sec + 1.0e-9*tend.tv_nsec) -
		((double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec));


}

int main(int argc,  char** argv){

	srand ( time(NULL) );
	BasicOps();
    //testRSA();
	return 0;
}
