import json
import os

class configuration:
    def __init__(self):
        with open("./Data/config.json") as f:
            config = json.load(f)

            self.numRXAntennas = int(config["mmWaveDevices"][0]["rfConfig"]["rlChanCfg_t"]["rxChannelEn"], 16).bit_count() # 4 RX antennas are always used
            # For SOME reason, for the boolean variable chInterleave, 0 represents interleaved, whereas 1 represents non-interleaved... ??
            self.interleaved = not(config["mmWaveDevices"][0]["rawDataCaptureConfig"]["rlDevDataFmtCfg_t"]) # Should always be false, it's easier to work with
            
            self.startFrequency = config["mmWaveDevices"][0]["rfConfig"]["rlProfiles"][0]["rlProfileCfg_t"]["startFreqConst_GHz"] # in GHz obviously
            self.freqSlope = config["mmWaveDevices"][0]["rfConfig"]["rlProfiles"][0]["rlProfileCfg_t"]["freqSlopeConst_MHz_usec"] # in MHz/us obviously
            self.rampEndTime = config["mmWaveDevices"][0]["rfConfig"]["rlProfiles"][0]["rlProfileCfg_t"]["rampEndTime_usec"] # in us
            self.idleTime = config["mmWaveDevices"][0]["rfConfig"]["rlProfiles"][0]["rlProfileCfg_t"]["idleTimeConst_usec"] # in us

            self.sampleRate = config["mmWaveDevices"][0]["rfConfig"]["rlProfiles"][0]["rlProfileCfg_t"]["digOutSampleRate"] 
            self.numADCSamples = config["mmWaveDevices"][0]["rfConfig"]["rlProfiles"][0]["rlProfileCfg_t"]["numAdcSamples"] # this will almost always be 256
            
            self.numFrames = config["mmWaveDevices"][0]["rfConfig"]["rlFrameCfg_t"]["numFrames"]
            self.numChirpsPerFrame = config["mmWaveDevices"][0]["rfConfig"]["rlFrameCfg_t"]["numLoops"]
            self.numChirps = self.numChirpsPerFrame * self.numFrames

