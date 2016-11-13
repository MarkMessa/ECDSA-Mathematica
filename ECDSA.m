(*
ECDSA for Mathematica 9
Package for signature generation and verification using ECDSA (elliptic curve digital signature algorithm) with parameters secp256k1.
*)

BeginPackage["ECDSA`"];

	ecPointModQ::usage="ecPointModQ[{a, b}, {x, y}, p] returns True if (x, y) is a coordinate of the elliptic curve E(Fp):y^2 = x^3 + a.x + b (mod p)";

	ecAddMod::usage="ecAddMod[{a, b}, {x1, y1}, {x2, y2}, p] returns the elliptic curve group point addition P1(x1, y1) + P2(x2, y2) over the finite field Fp. \n- The characteristic of the field must be a prime p. \n- The function accepts and returns {\[Infinity],\[Infinity]} for the group identity 0. \n- It returns {} if either point does not lie on the elliptic curve.";

	ecProductMod::usage="ecProductMod[{a, b}, Q, k, p] returns the scalar product k.Q in the abelian group of points on the elliptic curve E(Fp):y^2 = x^3 + a.x + b. This algorithm uses the binary representation of k to convert the problem into a series of doublings and additions in E(Fp).";

	secp256k1::usage = "The elliptic curve domain parameters (p, a, b, xg, yg, n, h) over Fp associated with a Koblitz curve secp256k1.";

	randomPrivateKeyECDSA::usage="randomPrivateKeyECDSA[] returns a random private key for ECDSA with parameters secp256k1.";

	publicKeyECDSA::usage="publicKeyECDSA[d] returns the public key associated with the private key integer d.";

	signECDSA::usage="signECDSA[z, d] returns the signature {r, s} of the integer z and the private key integer d using ECDSA with parameters secp256k1. Usually z is the hash of a message.";

	verifySignECDSA::usage="verifySignECDSA[z, {xh, yh}, {r, s}] returns True if the signature {r, s} of the integer z is associated with the public key {xh, yh}.";


	Begin["`Private`"];

		ecPointModQ[{a_,b_},{x_,y_},p_]:=Mod[PowerMod[x,3,p]+a x+b-PowerMod[y,2,p],p]==0;

		ecAddMod[{a_,b_},P1:{x1_,y1_},P2:{x2_,y2_},p_]:=Module[{m,x3,y3,w},

			(* Handle identity cases *)
			If[x1==\[Infinity],Return[P2]];
			If[x2==\[Infinity],Return[P1]];

			(* Q1 + (-Q1) = \[Infinity] *)
			If[x1==x2&&Mod[y1+y2,p]==0,Return[{\[Infinity],\[Infinity]}]];

			(* Verify that the points lie on the curve *)
			If[!ecPointModQ[{a,b},P1,p],Return[{}]];
			If[!ecPointModQ[{a,b},P2,p],Return[{}]];

			(* If doubling a point *)
			If[P1==P2,
				(* Check for vertical tangent *)
				If[y1==0,Return[{\[Infinity],\[Infinity]}]];
				(* Compute the slope of the tangent *)
				w=PowerMod[2 y1,-1,p];
				m=Mod[(3 x1^2+a)*w,p];
				,
				(* else compute the slope of the chord *)
				w=PowerMod[x2-x1,-1,p];
				m=Mod[(y2-y1)*w,p];
			];

			x3=Mod[m^2-x1-x2,p];
			y3=Mod[m(x1-x3)-y1,p];
			Return[{x3,y3}];
		];

		ecProductMod[{a_,b_},Q_,k_,p_]:=Module[{i,R,S},
			(* Verify that the point lie on the curve *)
			If[!ecPointModQ[{a,b},Q,p],Return[{}]];

			i=k;R={\[Infinity],\[Infinity]};S=Q;
			While[i!=0,
				If[EvenQ[i],
					i=Quotient[i,2];
					S=ecAddMod[{a,b},S,S,p];
					,
					i=i-1;
					R=ecAddMod[{a,b},R,S,p];
				];
			];
			Return[R];
		];

		secp256k1={
		"p"->(2^256-2^32-2^9-2^8-2^7-2^6-2^4-1),
		"a"->0,"b"->7,
		"xg"->55066263022277343669578718895168534326250603453777594175500187360389116729240,
		"yg"->32670510020758816978083085130507043184471273380659243275938904335757337482424,
		"n"->115792089237316195423570985008687907852837564279074904382605163141518161494337,
		"h"->1};

		randomPrivateKeyECDSA[]:=Module[{n="n"/.secp256k1},Random[Integer,{1,n-1}]];

		publicKeyECDSA[d_]:=Module[{
			(* secp256k1 *)
			p="p"/.secp256k1,
			a="a"/.secp256k1,b="b"/.secp256k1,
			xg="xg"/.secp256k1,yg="yg"/.secp256k1},

			ecProductMod[{a,b},{xg,yg},d,p]
		];

		signECDSA[z_,d_]:=Module[{
			(* secp256k1 *)
			p="p"/.secp256k1,
			a="a"/.secp256k1,b="b"/.secp256k1,
			xg="xg"/.secp256k1,yg="yg"/.secp256k1,
			n="n"/.secp256k1,
			h="h"/.secp256k1,

			k,xp,yp,xh,yh,r=0,s=0},

			(* If s=0, then choose another k and try again *)
			While[s==0,

				(* If r=0, then choose another k and try again *)
				While[r==0,
					k=Random[Integer,{1,n-1}];
					{xp,yp}=ecProductMod[{a,b},{xg,yg},k,p];
					r=Mod[xp,n] ;
				];

				{xh,yh}=ecProductMod[{a,b},{xg,yg},d,p];
				s=Mod[PowerMod[k,-1,n] (Mod[z+r d,n]),n];
			];

			(* The pair (r,s) is the signature *)
			{r,s}
		];

		verifySignECDSA[z_,H:{xh_,yh_},{r_,s_}]:=Module[{
			(* secp256k1 *)
			p="p"/.secp256k1,
			a="a"/.secp256k1,b="b"/.secp256k1,
			xg="xg"/.secp256k1,yg="yg"/.secp256k1,
			n="n"/.secp256k1,

			u1,u2,xp,yp,w1,w2},

			(* Verify that the public address point lie on the curve *)
			If[!ecPointModQ[{a,b},H,p],Return[False]];

			u1=Mod[PowerMod[s,-1,n] z,n];
			u2=Mod[PowerMod[s,-1,n] r,n];

			w1=ecProductMod[{a,b},{xg,yg},u1,p];
			w2=ecProductMod[{a,b},{xh,yh},u2,p];

			{xp,yp}=ecAddMod[{a,b},w1,w2,p]; 

			(* The signature is valid only if  r = xp mod n *)
			 r == Mod[xp,n]
		]


	End[];
EndPackage[];
