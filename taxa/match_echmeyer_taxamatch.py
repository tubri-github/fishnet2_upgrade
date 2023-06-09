import pandas as pd

taxamatch = pd.read_excel('C://work//Fishnet2//taxamatch_name_3000.xlsx')
ech = pd.read_excel('C://work//Fishnet2//ESCHMEYERS - Exports for Fishnet2//Fishnet2_Export_Species_new.xlsx')


for index, row in ech.iterrows():
    mask = taxamatch['final_name'] == row['orig_scientific_name']
    if mask.any():
        taxamatch.loc[mask, 'updated_name'] = row['curr_scientific_name']
        taxamatch.loc[mask, 'orig_name'] = row['orig_scientific_name']

taxamatch.to_excel('C://work//Fishnet2//updated_taxamatch.xlsx', index=False)