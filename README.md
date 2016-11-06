# ECDSA for Mathematica
This is a collection of functions for Mathematica in order to generate and verify a signature using ECDSA.
The main functions are:
- signECDSA[z, d] to generate a signature for the hash number z with the private key d
- verifySignECDSA[z, H, T] to verify if a signature T of the hash number z is from the public key H
