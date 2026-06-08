(* functions *)

Options[KinematicRules] = {QuarkMass -> 0};

KinematicRules[numFinalParticles_Integer /; numFinalParticles >= 2, OptionsPattern[
  ]] :=
  Module[{quarkMassOpt},
    quarkMassOpt = OptionValue["QuarkMass"];
    FCClearScalarProducts[];
    If[quarkMassOpt == 0,
      Which[
        numFinalParticles == 2,
          SPD[k1, k1] = 0;
          SPD[k2, k2] = 0;
          SPD[k1, k2] = q2 / 2
        ,
        numFinalParticles == 3,
          SPD[k1, k1] = 0;
          SPD[k2, k2] = 0;
          SPD[k3, k3] = 0;
          SPD[k1, k2] = s12 / 2;
          SPD[k1, k3] = s13 / 2;
          SPD[k2, k3] = s23 / 2
        ,
        numFinalParticles == 4,
          SPD[k1, k1] = 0;
          SPD[k2, k2] = 0;
          SPD[k3, k3] = 0;
          SPD[k4, k4] = 0;
          SPD[k1, k2] = s12 / 2;
          SPD[k1, k3] = s13 / 2;
          SPD[k1, k4] = s14 / 2;
          SPD[k2, k3] = s23 / 2;
          SPD[k2, k4] = s24 / 2;
          SPD[k3, k4] = s34 / 2
      ]
    ];
  ];

ApplyFeynCalcRules[expr_, numFinalParticles_] :=
  Module[{exprSubs, output},
    exprSubs = expr /. FeynAmpDenSub /. NegativePropDenSub;
    exprSubs = exprSubs /. FeynPropListSubs;
    output = exprSubs;
    output
  ];

StripCouplings[flag_, numFinalParticles_, numLoops_] :=
  Module[{electricCoupling, strongCoupling, output},
    electricCoupling = electricCouplingConstant * upQuarkElectricCharge
      ;
    strongCoupling = strongCouplingConstant ^ (numFinalParticles - 2 
      + 2 numLoops);
    Which[
      flag === False,
        output = 1
      ,
      flag === AllCouplings,
        output = electricCoupling * strongCoupling
      ,
      flag === ElectricCoupling,
        output = electricCoupling
      ,
      flag === StrongCoupling,
        output = strongCoupling
      ,
      Default,
        Print["Non-valid option inserted. Valid options are: AllCouplings, ElectricCoupling, StrongCoupling. Aborting..."
          ];
        $Failed
    ];
    output
  ];

MakeAmplitudeObject[expr_, n_, L_, colourMode_, couplingMode_, colourNorm_
  ] :=
  <|"Expression" -> expr, "NumFinalParticles" -> n, "LoopOrder" -> L,
     "ColourMode" -> colourMode, "CouplingMode" -> couplingMode, "AntennaColourNorm"
     -> colourNorm|>;

GluonColourBasisNorm[numGluons_] :=
  Module[{output},
    output = Sqrt[2] ^ numGluons;
    output
  ];

HasPolarizationVectorQ[expr_, mom_] :=
  !FreeQ[expr, Polarization[mom, ___]];

SafeDoPolarizationSums[expr_, mom_, ref_, opts___] :=
  If[HasPolarizationVectorQ[expr, mom],
    DoPolarizationSums[expr, mom, ref, opts]
    ,
    expr
  ];

SpinPolSum[expr_, numFinalParticles_] :=
  Module[{result, resultWhich, output},
    result =
      expr //
      FermionSpinSum //
      SafeDoPolarizationSums[#, p, 0, VirtualBoson -> True]&;
    Which[
      numFinalParticles == 3,
        resultWhich = SafeDoPolarizationSums[result, k3, 0]
      ,
      numFinalParticles == 4,
        resultWhich = SafeDoPolarizationSums[
          SafeDoPolarizationSums[result, k3, 0],
          k4,
          0
        ]
      ,
      Default,
        resultWhich = result
    ];
    resultWhich =
      resultWhich //
      DiracSimplify //
      Contract //
      Simplify;
    output = resultWhich;
    output
  ];

ColourTensorCounter[amp_] :=
  Module[{ampLen, count, term, output},
    ampLen = amp // Length;
    count = 0;
    Do[
      term = amp[[i]];
      If[Or[!FreeQ[term, SUNTF[__]], !FreeQ[term, SUNFDelta[__]]],
        count = count + 1
      ]
      ,
      {i, ampLen}
    ];
    output = count;
    output
  ];

ReturnColourSpinCouples[MAmp_] :=
  Module[{listTotal, cycleList, term},
    If[FreeQ[MAmp, Plus[__]],
      listTotal = {0, 0};
      Do[
        term = MAmp[[i]];
        If[Or[!FreeQ[term, SUNTF[__]], !FreeQ[term, SUNFDelta[__]]],
          listTotal[[1]] = term
          ,
          listTotal[[2]] = term
        ]
        ,
        {i, MAmp // Length}
      ]
      ,
      listTotal = ConstantArray[{0, 0}, MAmp // Length];
      Do[
        cycleList = {0, 0};
        Do[
          term = MAmp[[i]][[j]];
          If[Or[!FreeQ[term, SUNTF[__]], !FreeQ[term, SUNFDelta[__]]],
            
            cycleList[[1]] = term
            ,
            cycleList[[2]] = term
          ]
          ,
          {j, MAmp[[i]] // Length}
        ];
        listTotal[[i]] = cycleList
        ,
        {i, MAmp // Length}
      ];
    ];
    listTotal
  ];

