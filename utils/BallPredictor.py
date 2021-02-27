from typing import Dict, List
from DB import db_cursor
from pandas import DataFrame
from utils import prediction

class BallPredictor:
    
    def __init__(self, batsman:str, nonstriker:str, bowler:str, modelVars:List[str], predVars:List[str]):
        self.batsman = batsman
        self.bowler = bowler
        self.var_mods = modelVars
        self.var_preds = predVars
        self.prevTotalBallCount = 0
        self.prevTotalWickets = 0
        self.prevTotalRuns = 0
        self.ballcount = 6 #default for an over
    
    def setBallCount(self, ballcount : int):
        self.ballcount = ballcount
    
    def getBatVsBowlStats(self) -> DataFrame:
        db_cursor.callproc(f'league.getbatvsbowlstats', (self.batsman, self.bowler))
        return DataFrame(db_cursor.fetchall())
    
    def getInputDataFrame(self, totalDf:DataFrame, preds) -> Dict[str, DataFrame]:
        inputDict = {
            'batsmanid': totalDf['batsmanid'].iloc[0],
            'bowlerid': totalDf['bowlerid'].iloc[0],
        }
        if (preds is None):
            strikerate = { 
                'prevbatsmanstrikerate': totalDf['prevbatsmanstrikerate'].iloc[-1],
                'prevbowlerstrikerate': totalDf['prevbowlerstrikerate'].iloc[-1]
            }
        else:
            predDf = DataFrame([ preds ], columns=self.var_mods)
            strikerate = self.calculatePrevStrikeRates(predDf)
        
        return {
            'inpDf': DataFrame([{ **inputDict, **strikerate}]),
            'predDf': predDf,
        }

    def getDismissalData(self, dismissal):
        db_cursor.execute(f'''
            SELECT * FROM league.dismissals WHERE dismissal_id={dismissal}
        ''')
        return db_cursor.fetchall()[0]
    
    def calculatePrevStrikeRates (self, predDf:DataFrame):
        prev_bat_str_rt = 100 * self.prevTotalRuns/self.prevTotalBallCount
        prev_bow_str_rt = self.prevTotalBallCount/self.prevTotalWickets
        dismissal = self.getDismissalData(predDf['dismissal'].iloc[0])
        if dismissal['is_wicket'] and dismissal['is_wicket_to_bowler']:
            self.prevTotalWickets += 1
        
        if(predDf['batsmanruns'].iloc[0] > 0):
            self.prevTotalRuns += predDf['batsmanruns'].iloc[0]
        
        self.prevTotalBallCount += 1
        return {
            'prevbatsmanstrikerate': prev_bat_str_rt,
            'prevbowlerstrikerate': prev_bow_str_rt
        }
        
    def formInputDataFrame(self):
        totalDf = self.getBatVsBowlStats()
        self.prevTotalBallCount = totalDf['ballcount'].iloc[-1]
        self.prevTotalRuns = totalDf['sumruns'].iloc[-1]
        self.prevTotalWickets = totalDf['wicket'].iloc[-1]
        inputDf = DataFrame([{
            'batsmanid': totalDf['batsmanid'].iloc[0],
            'bowlerid': totalDf['bowlerid'].iloc[0],
            'prevbatsmanstrikerate': totalDf['prevbatsmanstrikerate'].iloc[-1],
            'prevbowlerstrikerate': totalDf['prevbowlerstrikerate'].iloc[-1]
        }])
        return {
            'totalDf': totalDf,
            'inputDf': inputDf
        }
        
    def changeBatsman(self, prediction):
        pass
    
    def predict(self, ballcount:int) -> DataFrame:
        dfDict = self.formInputDataFrame()
        predics = []
        self.predictBall(dfDict['totalDf'], dfDict['inputDf'], 1, ballcount, predics)
        return DataFrame(predics, index=range(1, len(predics) + 1), columns=self.var_mods)
    
    def predictBall(self, totalDf:DataFrame, inputDf:DataFrame, ball:int, maxballs:int, predics):
        sub = 1
        if (ball <= maxballs):
            predictions = prediction.prepare_data(totalDf, inputDf, self.var_preds, self.var_mods)
            # Should include logic for a batsman change if necessary after a ball is predicted
            newInpDf = self.getInputDataFrame(totalDf, predictions)
            predics.append(predictions)
            if (newInpDf['predDf']['wide'].iloc[0] > 0 or newInpDf['predDf']['noball'].iloc[0] > 0):
                sub = 0
            ball += sub
            self.predictBall(totalDf, newInpDf['inpDf'], ball, maxballs, predics)
    