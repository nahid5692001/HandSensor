@ECHO OFF
"C:\Program Files (x86)\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "Z:\2011junior\ece375_lab\lab4\labels.tmp" -fI -W+ie -o "Z:\2011junior\ece375_lab\lab4\lab4.hex" -d "Z:\2011junior\ece375_lab\lab4\lab4.obj" -e "Z:\2011junior\ece375_lab\lab4\lab4.eep" -m "Z:\2011junior\ece375_lab\lab4\lab4.map" "Z:\2011junior\ece375_lab\lab4\ece375_lab4_src.asm"
