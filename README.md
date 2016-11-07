# ECDSA for Mathematica
## Brief Overview
This is a collection of functions for Mathematica in order to generate and verify a signature using ECDSA with standard parameters `secp256k1`. The main functions are:
- signECDSA[z, d] to generate a signature for the hash number z with the private key d
- verifySignECDSA[z, H, T] to verify if a signature T of the hash number z is from the public key H
- randomPrivateKeyECDSA[] returns a random private key for ECDSA
- publicKeyECDSA[d] returns the public key associated with the private key d

A simple usage example:
```Mathematica
(* generate a random private key *)
In[1]:= d = randomPrivateKeyECDSA[]
Out[1]:= 93602568143572437497047345193536924976274605889652076707509844737444328626670

(* generate the public key associated with private key d *)
In[2]:= {xh,yh}=publicKeyECDSA[d]
Out[2]:= {87943153917328339238098758968986858868870060847632433257348495687910286253282, 114510692297125386214880916984900906876306824610921820870708215390655128572828}

(* find the hash of a message *)
In[3]:= z=Hash["Hello World!","SHA256"]
Out[3]:= 57676413081093003148005107550719583540116985236696423860923466490497932824681

(* sign the message hash *)
In[4]:= {r,s}=signECDSA[z,d]
Out[4]:= {52645229419831756461156602966389193516169924018897850564955063216321799997576, 105208277479664712928314923396354361130135526252419945028148626557358697529330}

(* verify if the signature is correct *)
In[5]:= verifySignECDSA[z,{xh,yh},{r,s}]
Out[5]:= True

(* verify if a random signature is correct *)
In[6]:= verifySignECDSA[z,{xh,yh},{randomPrivateKeyECDSA[],randomPrivateKeyECDSA[]}]
Out[6]:= False
```

##Code Structure
The code is divided in two main parts:

1. Elliptic curve operations over a finite field of integers modulo p
  - definition of point addition and scalar multiplication
  
2. Digital signing using ECDSA with standard parameters `secp256k1`
  - key pair generation
  - setup of `secp256k1` standard parameters
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
Fast theoretical background:

1. [Andrea Corbellini, Elliptic Curve Cryptography: a gentle introduction](http://andrea.corbellini.name/2015/05/17/elliptic-curve-cryptography-a-gentle-introduction/)
2. [Andrea Corbellini, Elliptic Curve Cryptography: Elliptic Curve Cryptography: finite fields and discrete logarithms](http://andrea.corbellini.name/2015/05/23/elliptic-curve-cryptography-finite-fields-and-discrete-logarithms/)

Reference code implementation:

3. [John McGee, M.Sc Thesis in Elliptic Curve Cryptography: pg 57-58](https://theses.lib.vt.edu/theses/available/etd-04252006-161727/unrestricted/SchoofsAlgorithmThesisMcGee.pdf)
