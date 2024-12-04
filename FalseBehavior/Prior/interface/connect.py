RSTD_DLL_Path = "C:\\ti\\mmwave_studio_03_01_01_00\\mmWaveStudio\\Clients\\RtttNetClientController\\RtttNetClientAPI.dll"

import clr
import os
import sys
import time

def Init_RSTD_Connection(RSTD_DLL_Path):

    clr.AddReference(RSTD_DLL_Path)
    from RtttNetClientAPI import RtttNetClient
    ErrStatus = RtttNetClient.Init()


    ErrStatus = RtttNetClient.Init()
    ErrStatus = RtttNetClient.Connect('127.0.0.1',2777)

    #lua_string1 = r"""ar1.CaptureCardConfig_StartRecord("C:\\Users\\bljor\\Desktop\\Repo\\Data\\verify\\verify.bin", 1)"""
    #ErrStatus = RtttNetClient.SendCommand(lua_string1)

    time.sleep(1)

    lua_string2 = 'ar1.StartFrame()'
    ErrStatus = RtttNetClient.SendCommand(lua_string2)


ErrStatus = Init_RSTD_Connection(RSTD_DLL_Path)




