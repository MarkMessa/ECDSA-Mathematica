# ECDSA for Mathematica 9.0
## Quick Overview
This is a collection of functions for Mathematica 9.0 in order to generate and verify a signature using ECDSA with standard parameters `secp256k1`. The main functions are:
- signECDSA[z, d] to generate a signature for the hash number z with the private key d
- verifySignECDSA[z, H, T] to verify if a signature T of the hash number z is from the public key H
- randomPrivateKeyECDSA[] returns a random private key for ECDSA
- publicKeyECDSA[d] returns the public key associated with the private key d

A simple usage example:
```Mathematica
(* Load Package *)
In[1]:= Get[FileNameJoin[{NotebookDirectory[],"ECDSA.m"}]];

(* generate a random private key *)
In[2]:= d = randomPrivateKeyECDSA[]
Out[2]:= 93602568143572437497047345193536924976274605889652076707509844737444328626670

(* generate the public key associated with private key d *)
In[3]:= {xh,yh}=publicKeyECDSA[d]
Out[3]:= {87943153917328339238098758968986858868870060847632433257348495687910286253282, 114510692297125386214880916984900906876306824610921820870708215390655128572828}

(* find the hash of a message *)
In[4]:= z=Hash["Hello World!","SHA256"]
Out[4]:= 57676413081093003148005107550719583540116985236696423860923466490497932824681

(* sign the message hash *)
In[5]:= {r,s}=signECDSA[z,d]
Out[5]:= {52645229419831756461156602966389193516169924018897850564955063216321799997576, 105208277479664712928314923396354361130135526252419945028148626557358697529330}

(* verify if the signature is correct *)
In[6]:= verifySignECDSA[z,{xh,yh},{r,s}]
Out[6]:= True

(* verify if a random signature is correct *)
In[7]:= verifySignECDSA[z,{xh,yh},{randomPrivateKeyECDSA[],randomPrivateKeyECDSA[]}]
Out[7]:= False
```

##Code Structure
The code is divided in two main parts:

1. Elliptic curve operations over a finite field of integers modulo p
  - definition of point addition and scalar multiplication
  
2. Digital signing using ECDSA with standard parameters `secp256k1`
  - setup of `secp256k1` standard parameters
  - key pair generation
  - signing the hash of a message
  - signature verification

##Pseudo-Codes
###Elliptic curve operations over a finite field of integers modulo p
####Point addition: Function ecAddMod
Given P=(xp, yp), Q=(xq, yq) and R=(xr, yr), we can calculate the point addition P+Q=−R as follows:
```
xr=(m^2−xp−xq) mod p
yr=[yp+m(xr−xp)] mod p
  =[yq+m(xr−xq)] mod p
```
If P≠Q, the slope m assumes the form:
```
m=(yp−yq)(xp−xq)^−1 mod p
```
Else, if P=Q, we have:
```
m=(3xp^2+a)(2yp)^−1 mod p
```
####Scalar Multiplication: Function ecProductMod
Other than addition, we can define another operation: scalar multiplication, that is:
```
nP=P+P+⋯+P (n times)
```
Written in that form, it seems that computing nP requires n additions. If n has k binary digits, then our algorithm would be O(2^k), which is not really good. However, there exist faster algorithms. One of them is the double and add algorithm.
Its principle of operation can be better explained with an example. Take n=151. We can write:
```
151⋅P=(2^7)P+(2^4)P+(2^2)P+(2^1)P+(2^0)P
```
What the double and add algorithm tells us to do is:
```
Take P.
Double it, so that we get 2P.
Add 2P to P (in order to get the result of (2^1)P+(2^0)P.
Double 2P, so that we get (2^2)P.
Add it to our result (so that we get (2^2)P+(2^1)P+(2^0)P.
Double (2^2)P to get (2^3)P.
Don't perform any addition involving (2^3)P.
Double (2^3)P to get (2^4)P.
Add it to our result (so that we get (2^4)P+(2^2)P+(2^1)P+(2^0)P.
...
```
####References
Quick theoretical background:

1. [Andrea Corbellini, Elliptic Curve Cryptography: a gentle introduction](http://andrea.corbellini.name/2015/05/17/elliptic-curve-cryptography-a-gentle-introduction/)
2. [Andrea Corbellini, Elliptic Curve Cryptography: Elliptic Curve Cryptography: finite fields and discrete logarithms](http://andrea.corbellini.name/2015/05/23/elliptic-curve-cryptography-finite-fields-and-discrete-logarithms/)

Reference code implementation:

3. [John McGee, M.Sc Thesis in Elliptic Curve Cryptography: pg 57-58](https://theses.lib.vt.edu/theses/available/etd-04252006-161727/unrestricted/SchoofsAlgorithmThesisMcGee.pdf)

###Digital signing using ECDSA with standard parameters `secp256k1`
####Setup of `secp256k1` standard parameters
The elliptic curve domain parameters over Fp associated with a Koblitz curve secp256k1 are specified by:
  - p = 0xffffffff ffffffff ffffffff ffffffff ffffffff ffffffff fffffffe fffffc2f
  - a = 0
  - b = 7
  - xg = 0x79be667e f9dcbbac 55a06295 ce870b07 029bfcdb 2dce28d9 59f2815b 16f81798
  - yg = 0x483ada77 26a3c465 5da4fbfc 0e1108a8 fd17b448 a6855419 9c47d08f fb10d4b8
  - n = 0xffffffff ffffffff ffffffff fffffffe baaedce6 af48a03b bfd25e8c d0364141
  - h = 1

####Key pair generation: Functions randomPrivateKeyECDSA and publicKeyECDSA
  - The private key is a random integer d chosen from {1,…,n−1} (where n is the order of the subgroup).
  - The public key is the point H=dG (where G is the base point of the subgroup).

####Signing the hash of a message: Function signECDSA
ECDSA works on the hash of the message, rather than on the message itself. The truncated hash is an integer and will be denoted as z. The algorithm performed to sign the message works as follows:

```
1. Take a random integer k chosen from {1,…,n−1} (where n is still the subgroup order).
2. Calculate the point P=kG (where G is the base point of the subgroup).
3. Calculate the number r=xp mod n (where xp is the x coordinate of P).
4. If r=0, then choose another k and try again.
5. Calculate s=(k^−1)(z+rd) mod n (where d is the private key and k^−1 is the multiplicative inverse of k modulo n).
6. If s=0, then choose another k and try again.
7. The pair (r,s) is the signature.
```

####Signature verification: Function verifySignECDSA
In order to verify the signature it is necessary the public key H, the (truncated) hash z and, obviously, the signature (r,s).

```
1. Calculate the integer u1=(s^−1)z mod n.
2. Calculate the integer u2=(s^−1)r mod n.
3. Calculate the point P=u1G+u2H.
4. The signature is valid only if r=xp mod n.
```

####References

1. [Certicom Research, Standards for Efficient Cryptography 2.0: Recommended Elliptic Curve Domain Parameters, pg 9](http://www.secg.org/sec2-v2.pdf)
2. [Andrea Corbellini, Elliptic Curve Cryptography: ECDH and ECDSA](http://andrea.corbellini.name/2015/05/30/elliptic-curve-cryptography-ecdh-and-ecdsa/)


##Validation
For validation purposes it was used [jsrsasign](https://kjur.github.io/jsrsasign/sample-ecdsa.html) which is an opensource free pure JavaScript cryptographic library that supports, among others, ECDSA `secp256k1` via internet browser. Basically, the validation consisted of signing some message with the Mathematica Code and than confirm the signature with 'jsrsasign':
- [Test-Vectors File](https://github.com/MarkMessa/ECDSA-Mathematica/blob/master/Test-Vectors.txt)
