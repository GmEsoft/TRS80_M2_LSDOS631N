@echo off
for %%X in (.BAK .PRN .TMP _DASM.ASM .DMK .DSK .HFE .IMD) do del /S /Q *%%X
