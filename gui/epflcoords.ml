(*                                  *)
(* mws  multihop wireless simulator *)
(*                                  *)

(** Graph representation of EPFL campus *)


let l = [
"BP 386 290 408 290 408 159 386 159 AN-1 AN-2 P-ARCHI";
"SG 291 352 369 352 369 271 291 270 SG-D SG-C SG-B P-ARCHI AN-2";
"SG-D 197 286 290 286 290 271 197 271 SG";
"SG-C 182 319 290 319 290 303 182 303 SG";
"SG-B 167 352 290 352 290 337 167 337 SG";
"AN-1 409 290 428 290 428 162 409 162 BP AN-2 BM";
"AN-2 370 372 428 370 428 291 370 291 SG BM BP AI AN-1 ESP-1";
"BM 428 394 455 394 455 148 428 148 AN-1 AN-2 ESP-1";
"AI 197 393 413 393 413 373 197 373 AN-2 ESP-1 P-CO";
"CO-2 343 476 379 476 379 423 343 423 DIA-1 CO-1 P-CO ESP-1";
"CO-1 437 475 468 475 468 435 437 435 DIA-1 CO-2 ESP-1 ESP-2 ESP-3";
"EL-B 393 545 454 545 454 516 393 516 EL-A A-SAV-4";
"EL-A 351 537 358 542 389 517 380 506 EL-B DIA-1";
"MXC 260 520 321 520 320 497 260 497 DIA-1 MXD";
"MXD 184 520 243 520 243 496 184 496 MXC MXE";
"MXE 101 526 168 526 168 488 101 488 MXD";
"MXF 250 588 266 588 266 562 250 562 MXG DIA-3";
"MXG 182 582 244 582 244 557 182 557 MXF MXH";
"MXH 101 590 168 590 168 552 101 552 MXG";
"INN 116 667 178 667 178 640 116 640 INM";
"INM 183 684 213 713 244 684 213 653 INN INR INF INJ DIA-3 R-COL-2";
"INF 249 667 311 667 311 639 249 639 INM ELG";
"INJ 249 728 311 728 311 700 249 700 INM";
"INR 116 729 177 729 177 700 116 700 INM";
"ELE-1 320 606 382 606 382 578 320 578 ELE-2 ELE-3 DIA-3";
"ELE-2 392 606 454 606 454 578 392 578 ELE-1 ELE-4 A-SAV-3";
"ELE-3 362 638 383 638 383 607 362 607 ELE-1 ELG";
"ELE-4 419 637 442 637 442 608 419 608 ELE-2 ELH A-SAV-3";
"ELG 321 666 381 666 381 638 321 638 ELH INF ELE-3";
"ELH 393 672 453 672 453 638 393 638 ELG ELE-4";
"ELL 423 730 453 730 453 699 423 699 A-SAV-1";
"PSE-B 55 810 107 810 107 792 55 792 PSE-A";
"PSE-A 126 810 179 810 179 792 126 792 PSE-B PSE-C P-PSE R-COL-3";
"PSE-C 153 898 178 898 178 832 153 832 PSE-A";
"PPH 335 872 368 872 368 791 335 791 R-COL-1 P-PSE R-COL-1 PPB";
"TCV 392 858 442 858 442 791 392 791 R-COL-1";
"PPB 361 899 399 899 399 888 361 888 PPH";
"DIA-1 324 540 332 546 421 456 412 450 DIA-2 CO-1 CO-2 MXC EL-A ESP-1";
"DIA-2 300 565 307 570 331 548 325 541 DIA-1 DIA-3";
"DIA-3 210 643 225 649 306 573 293 565 DIA-2 INM ELE-1 MXF";
"ESP-1 413 421 479 421 479 395 413 395 AN-2 DIA-1 CO-1 CO-2 AI BM";
"ESP-2 476 430 540 430 540 387 476 387 I-1 I-2 A-SAV-4 ESP-3 CO-1 CM";
"ESP-3 476 485 540 485 540 430 476 430 ESP-2 CO-1 ME-C";
"I-1 474 381 495 381 495 343 474 343 GC-D ESP-2 I-2";
"I-2 514 383 535 383 535 343 514 343 GC-C I-1 ESP-2";
"GC-H 514 220 545 220 545 158 514 158 GC-G R-SOR-1";
"GC-G 545 271 575 270 575 158 545 158 GC-H GC-F GC-B R-SOR-1";
"GC-F 587 270 637 270 637 180 587 180 GC-A GC-G";
"GC-D 473 342 494 342 494 301 473 301 I-1 GC-C";
"GC-C 515 342 534 342 534 301 515 301 GC-D I-2 GC-B";
"GC-B 555 341 575 341 575 271 555 271 GC-G GC-C GC-A";
"GC-A 596 360 615 360 615 271 596 271 GC-B GC-F CM GR-B";
"LE 658 213 688 213 688 158 658 158 R-SOR-1 PO";
"CM 555 402 719 402 719 363 555 363 GC-A ME-B GR-B GR-A MA-A CE-1 ME-C ESP-2";
"GR-B 677 341 698 341 698 302 677 302 GR-A CM GC-A";
"GR-A 719 352 738 352 738 300 719 300 CM GR-B GR-C";
"GR-C 718 300 739 300 739 230 718 230 GR-A";
"ME-C 556 464 575 464 575 424 556 424 CM ME-B ESP-3";
"ME-B 597 500 616 500 616 403 597 403 CM ME-C ME-A ME-H";
"ME-A 637 484 657 484 657 433 637 433 ME-G ME-B MA-A";
"ME-H 575 566 627 566 627 484 575 484 ME-B ME-G R-NOY-4";
"ME-G 627 566 677 566 677 485 627 485 ME-H ME-A R-NOY-4";
"A-SAV-1 474 762 553 762 553 700 474 700 A-SAV-2 R-COL-1 ELL";
"A-SAV-2 474 700 553 700 553 640 474 640 A-SAV-1 A-SAV-3 P-MECA ";
"A-SAV-3 474 640 553 640 553 580 474 580 A-SAV-2 A-SAV-4  R-NOY-4 N S ELE-4 ELE-2";
"A-SAV-4 474 580 553 580 553 514 474 514 ESP-2 R-NOY-4 EL-B A-SAV-3";
"L 616 636 636 637 636 608 616 608 P-MECA R-NOY-4";
"N 568 622 596 622 596 613 568 613 S A-SAV-3 R-NOY-4";
"S 568 641 602 641 602 631 568 631 N A-SAV-3 P-MECA";
"MA-A 700 475 750 475 750 434 700 434 MA-B CM BI ME-A";
"MA-B 699 515 750 515 750 475 699 475 MA-A MA-C BI";
"MA-C 698 566 749 566 750 516 698 516 MA-B";
"PC 807 635 881 635 881 617 807 617 R-NOY-3 PB P-MECA";
"PB 911 643 962 643 962 626 911 626 PC PA-C";
"BI 821 494 881 494 881 455 821 455 CE-1 R-NOY-3 MA-A MA-B CH-A";
"PO 833 239 861 248 871 219 842 211 PH-H LE";
"PH-H 831 311 872 311 872 271 831 271 PH-A PO";
"PH-A 831 331 872 331 872 312 831 312 PH-H PH-B PH-C CE-1";
"PH-B 881 341 922 341 922 312 881 312 PH-A PH-C CE-1";
"PH-C 923 332 945 332 945 280 923 280 PH-A PH-B PH-D PH-J PH-K CE-2";
"PH-D 963 350 982 350 982 267 963 267 PH-K PH-L PH-C CE-2";
"PH-J 902 280 922 280 922 240 902 240 PH-C";
"PH-K 944 280 963 280 963 240 944 240 PH-C PH-D";
"PH-L 984 280 1046 280 1046 239 984 239 PH-D P-PHY";
"CE-1 818 403 930 403 930 362 818 362 PH-A PH-B BI CM CH-A ";
"CE-2 930 403 1066 403 1066 362 930 362 PH-C PH-D CH-B CH-C BS ";
"ST 1035 454 1066 454 1066 434 1035 434 CH-C";
"CH-F 912 566 964 566 964 486 912 486 CH-G CH-A R-NOY-2 ";
"CH-G 964 567 1004 567 1004 485 964 485 CH-F CH-H CH-B R-NOY-2";
"CH-H 1004 566 1025 566 1025 485 1004 485 CH-G CH-J CH-C R-NOY-2";
"CH-J 1025 505 1066 505 1066 485 1025 485 CH-H CH-C";
"CH-A 922 484 944 484 944 415 922 415 CH-B CE-1 CH-F BI";
"CH-B 963 485 984 484 984 414 963 414 CH-C CH-A CE-2 CH-G";
"CH-C 1004 484 1024 484 1024 415 1004 415 CH-B ST CE-2 CH-J CH-H";
"BS 1096 454 1125 454 1125 312 1096 312 CE-2 P-PHY A-FOR-2";
"PA-C 994 688 1025 688 1024 619 994 619 PA-A PB";
"PA-A 1025 647 1045 647 1045 642 1025 642 PA-C PA-B R-NOY-2";
"PA-B 1046 668 1076 668 1075 617 1046 617 PA-A";
"P-ARCHI 236 254 355 254 355 193 236 193 SG BP A-PERO-3";
"P-CO 142 467 324 467 324 415 142 415 AI CO-2 A-PERO-2";
"P-MECA 571 762 767 762 767 649 571 649 A-SAV-2 L S PC";
"P-PSE 196 813 311 813 311 765 196 765 PPH R-COL-2 PSE-A ";
"P-PHY 1056 291 1107 291 1107 222 1056 222 PH-L BS";
"P-CHI 1083 562 1133 562 1133 489 1083 489 R-NOY-1";
"P-FAV 493 98 578 98 578 44 494 45 TSOL";
"R-COL-1 315 761 461 761 461 751 315 751 PPH TCV A-SAV-1 R-COL-2";
"R-COL-2 187 761 315 761 315 751 187 751 R-COL-1 R-COL-3 INM P-PSE";
"R-COL-3 72 761 187 761 187 751 72 751 R-COL-2 PSE-A";
"R-NOY-1 1026 592 1153 592 1155 580 1026 580 P-CHI R-NOY-2 A-FOR-1";
"R-NOY-2 897 592 1026 592 1026 580 897 580 R-NOY-1 CH-F CH-G CH-H R-NOY-3 PA-A";
"R-NOY-3 711 592 897 592 897 580 711 580 R-NOY-2 R-NOY-4 PC BI";
"R-NOY-4 548 592 711 592 711 580 548 580 R-NOY-3 ME-H ME-G A-SAV-3 A-SAV-4 N L";
"A-FOR-1 1155 595 1168 595 1168 493 1155 493 R-NOY-1 A-FOR-2";
"A-FOR-2 1155 493 1168 493 1168 216 1155 216 A-FOR-1 BS ";
"A-PERO-1 23 644 33 645 103 459 95 457 A-PERO-2";
"A-PERO-2 95 457 103 459 162 324 151 320 P-CO A-PERO-1 A-PERO-3";
"A-PERO-3 151 320 162 324 227 181 213 178 A-PERO-2 P-ARCHI";
"TSOL 407 120 617 120 617 101 407 101 R-SOR-1 P-FAV";
"R-SOR-1 445 139 679 139 679 132 445 132 TSOL GC-H GC-G LE"]
