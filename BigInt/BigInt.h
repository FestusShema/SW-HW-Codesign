#ifndef BigInt_H
	#define BigInt_H

class BigInt{

	public:
	int size;
	unsigned int *digit;
	BigInt(){};
	BigInt (int n);
	BigInt (const BigInt& k); //some object k
	~BigInt();
	void addBigInt(BigInt& a, BigInt& b, BigInt& result);
	void subBigInt(BigInt& a, BigInt& b, BigInt& result);
	void multiplyBigInt(BigInt& a, BigInt& b, BigInt& result);
	void copyBigInt(BigInt& a, int index);
	void gcdBigInt(BigInt& a, BigInt& b, BigInt& result);
	void clearBigInt();
	void displayBigInt();
	int msbBigInt();
	//bool primeBigInt(BigInt& a, int index);
	void expoModNBigInt(BigInt& a, BigInt& b, BigInt& N, BigInt& result);
	void randBigInt(int n);
	void generatePhiBigInt(BigInt& a, BigInt& b, BigInt& result);
	void generateEBigInt(BigInt& a, BigInt& result);
	void generateDBigInt(BigInt& a, BigInt& b,BigInt& result);
	void RSABigInt(int flag, BigInt& input, BigInt& result);
};

int divideBigInt(BigInt& a, BigInt& b,BigInt& q, BigInt& r );
int compareBigInt(BigInt& a, BigInt& b);

#endif // BigInt_H
