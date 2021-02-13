
import numpy as np # linear algebra
import pandas as pd
from pandas.core.frame import DataFrame # data processing, CSV file I/O (e.g. pd.read_csv)
#Import models from scikit learn module:
# from sklearn.linear_model import LogisticRegression
# from sklearn.ensemble import RandomForestClassifier
from sklearn.tree import DecisionTreeClassifier, DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor
from sklearn import metrics
from typing import Dict, List
#building predictive model , convert categorical to numerical data
from sklearn.preprocessing import LabelEncoder

#Generic function for making a classification model and accessing performance:
def classification_model(model, data, predictors, outcome):
    model.fit(data[predictors],data[outcome])
    predictions = model.predict(data[predictors])
    print(predictions)
    accuracy = metrics.accuracy_score(predictions,data[outcome])
    print('Accuracy : %s' % '{0:.3%}'.format(accuracy))
    return {
        'predictions': predictions,
        'accuracy': accuracy
    }

def tranformToNumeric(dataframe: DataFrame, var_mod: List[str]) -> Dict:
    label_enc = LabelEncoder()
    for i in var_mod:
        dataframe[i] = label_enc.fit_transform(dataframe[i])
    return {
        'dataframe': dataframe,
        'labelEnc': label_enc
    }

def prepare_data(dataframe, df, var_preds, var_mod):
    # dataframe = pd.read_sql_query('''
    #     SELECT 
    #         batsman_id,
    #         bowler_id,
    #         over,
    #         ball,
    #         CASE WHEN dismissal_kind IS NULL OR COALESCE(TRIM(dismissal_kind), '') = '' THEN
    #             CASE 
    #                 WHEN batsman_runs = 0 and extra_runs <= 0 AND dismissal_kind IS NULL THEN 0::text
    #                 WHEN batsman_runs > 0 and (extra_runs IS NULL or extra_runs < 1) AND dismissal_kind IS NULL THEN batsman_runs::text
    #                 WHEN legbye_runs > 0 THEN legbye_runs::text || 'LB'
    #                 WHEN bye_runs > 0 THEN bye_runs::text || 'B'
    #                 WHEN wide_runs > 0 THEN wide_runs::text || 'W'
    #                 WHEN noball_runs > 0 THEN total_runs::text || 'NB'
    #                 WHEN penalty_runs > 0 THEN penalty_runs::text || 'PEN'
    #             ELSE
    #                 'NoDecision'
    #             END
    #         ELSE
    #             dismissal_kind
    #         END decision
    #     FROM league."Deliveries";''', dbconn)
    # convert categorical data to a numerical one
    
    # transformDict = tranformToNumeric(dataframe, var_mod)
    # dataframe = transformDict['dataframe']
    if (df is not None):
        model = trainData(dataframe, var_preds, var_mod)
        preds = model.predict(df[var_preds])
    else:
        preds = predict_based_on_model(dataframe, var_preds, var_mod)
    return getPredictions(preds)

def getPredictions(preds, transformDict=None):
    predictions = [int(pred) for pred in preds.flatten()]
    # dismissal_ind = int(predictions[-1])
    # dismissal = transformDict['labelEnc'].inverse_transform([ dismissal_ind ])[0]
    return predictions

def np_to_py_native_convert(o):
    if isinstance(o, np.int64):
        return int(o)
    elif isinstance(o, np.floating):
        return float(o)
    elif isinstance(o, np.ndarray):
        return o.tolist()
    return o


def trainData(dataframe, xvars, yvars):
    # model = DecisionTreeClassifier(criterion='gini', random_state=0)
    # np.random.RandomState(15)
    # model = DecisionTreeClassifier(criterion='gini')
    # model = DecisionTreeRegressor()
    model = RandomForestRegressor()
    X, Y = dataframe[xvars], dataframe[yvars]
    model.fit(X, Y)
    return model

def predict_based_on_model(dataframe, prediction_var, outcome_var, modeltype='decisiontree'):
    # if(modeltype == 'decisiontree'):
    model = DecisionTreeRegressor()
    return classification_model(model, dataframe, prediction_var, outcome_var)