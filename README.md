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
