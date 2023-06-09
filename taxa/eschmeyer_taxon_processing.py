import uuid

import pandas as pd
import psycopg2,sys

conn = psycopg2.connect(database='hdr_image_info',user='postgres',host='10.10.62.35',password='postgres',port='5432')
cur = conn.cursor()



####IMPORT Files##########
df_Genera = pd.read_csv('eschmeyer_taxon_csv_files/Fishnet2_Export_Genera.csv',dtype={'CurrentGenusID':str,'LineageID':str,'CAS_REF_NO':str,'YR_TYP_SP':str})
df_Species = pd.read_csv('eschmeyer_taxon_csv_files/Fishnet2_Export_Species.csv',dtype={'CAS_REF_NO':str,'LineageID':str,'Curr_GenusID':str})
df_Lineages = pd.read_csv('eschmeyer_taxon_csv_files/Fishnet2_Export_Lineages_proccessed.csv',dtype={'ClassNum':str,'OrderNum':str,'SuborderNum':str,'FamilyNum':str,'SubfamilyNum':str})
df_References = pd.read_csv('eschmeyer_taxon_csv_files/Fishnet2_Export_References.csv',dtype={'CAS_REF_NO':str})
df_Journals = pd.read_csv('eschmeyer_taxon_csv_files/Fishnet2_Export_Journals.csv')
df_Rank = pd.read_csv('eschmeyer_taxon_csv_files/rank.csv',dtype={'id':str})

#df_new = df_synom.merge(df_origin, on='fullcurrname')
#merge rank with lineages
df_Lineages_rank = df_Lineages.merge(df_Rank,left_on="Rank_name",right_on="rank",how="left")
df_Lineages_taxon = pd.DataFrame(df_Lineages_rank,
                                        columns=["LineageID", "NAME", "Parent_id", "id"])
df_Lineages_taxon = df_Lineages_taxon.rename(columns={"LineageID":"id", "NAME":"name", "Parent_id":"parent_id", "id":"rank_id"})
df_Lineages_taxon['reference_id'] = ""
df_Lineages_taxon['status'] = ""
df_Lineages_taxon = pd.DataFrame(df_Lineages_taxon,
                                        columns=["id", "name", "parent_id","reference_id", "rank_id","status"])


#######GENERA##########
#merge rank with Genera
df_Genera["rank_name"] = "Genus"
df_Genera_rank = df_Genera.merge(df_Rank,left_on="rank_name",right_on="rank",how="left")


df_Genera_rank['CAS_GEN_2000'] = df_Genera['CAS_GEN'] + 2000
df_Genera_rank_nonnan =df_Genera_rank[df_Genera_rank['CurrentGenusID'].notna()]
df_Genera_rank_nonnan.CurrentGenusID = pd.to_numeric(df_Genera_rank_nonnan.CurrentGenusID, errors='coerce')
df_Genera_rank_nonnan['CurrentGenusID_2000'] = df_Genera_rank_nonnan['CurrentGenusID'].fillna(0) + 2000

# genera taxon
df_Genera_rank_taxon = pd.DataFrame(df_Genera_rank,
                                        columns=["CAS_GEN_2000", "GEN_NAME", "LineageID", "CAS_REF_NO", "id", "STAT_CODE"])
df_Genera_rank_taxon = df_Genera_rank_taxon.rename(
        columns={"CAS_GEN_2000": "id", "GEN_NAME": "name", "LineageID": "parent_id", "CAS_REF_NO": "reference_id",
                 "id": "rank_id", "STAT_CODE": "status"})
#a.genera synom
df_Genera_synom = pd.DataFrame(df_Genera_rank_nonnan, columns=['CAS_GEN_2000','CurrentGenusID_2000'])
df_Genera_synom=df_Genera_synom.rename(columns={'CAS_GEN_2000':'taxon_id','CurrentGenusID_2000':'taxon_accepted_id'})

#######SPECIES##########
df_Species['fullorigname'] = df_Species['ORIG_NAME'].str.cat(df_Species['TAXON_NAME'], sep=' ')
# merge rank with species
df_Species['ORIG_LEVEL'] = df_Species['ORIG_LEVEL'].str.upper()
df_Rank['rank'] = df_Rank['rank'].str.upper()
df_Species_rank = df_Species.merge(df_Rank, left_on="ORIG_LEVEL", right_on="rank", how="left")

# species with current genus id
df_Species_rank['CAS_SPC_20000'] = df_Species['CAS_SPC'] + 20000
df_Species_rank_nonnan = df_Species_rank[df_Species_rank['Curr_GenusID'].notna()]
df_Species_rank_nonnan.Curr_GenusID = pd.to_numeric(df_Species_rank_nonnan.Curr_GenusID, errors='coerce')
df_Species_rank_nonnan['Curr_GenusID_2000'] = df_Species_rank_nonnan['Curr_GenusID'].fillna(0) + 2000

df_Genera_refer = pd.DataFrame(df_Genera_rank,
                               columns=["CAS_GEN_2000", "GEN_NAME"])
df_Species_rank_nonnan = df_Species_rank_nonnan.merge(df_Genera_refer, left_on="Curr_GenusID_2000",
                                                      right_on="CAS_GEN_2000", how="left")
df_Species_rank_nonnan = df_Species_rank_nonnan.merge(df_Genera_rank_nonnan)
df_Species_rank_nonnan = df_Species_rank_nonnan.merger
# species_valid  if curr_name= null, make sure stats code don't contain 'valid' ver1 :no
#only valid taxon has parent id
df_Species_rank_nonnan['fullcurrname'] = df_Species_rank_nonnan['GEN_NAME'].str.cat(df_Species_rank_nonnan['CURR_NAME'], sep=' ')
df_Species_rank_nonnan_valid =df_Species_rank_nonnan[df_Species_rank_nonnan['STAT_CODE'] == 'Valid']

#b.species_synom 1.species_valid ->current name, old name 2.species without curr name
#df_new = df_synom.merge(df_origin, on='fullcurrname')
df_Species_rank_nonnan_valid_for_merge = pd.DataFrame(df_Species_rank_nonnan_valid, columns=['CAS_SPC_20000','fullcurrname','fullorigname'])

df_Species_rank_nonnan_for_merge = pd.DataFrame(df_Species_rank_nonnan, columns=['CAS_SPC_20000','fullcurrname','fullorigname'])
df_Species_synom = df_Species_rank_nonnan_valid_for_merge.merge(df_Species_rank_nonnan_for_merge, on="fullcurrname")
df_Species_synom_rename = pd.DataFrame(df_Species_synom,columns=['CAS_SPC_20000_y','CAS_SPC_20000_x'])
#df_Species_synom_rename = df_Species_synom_rename[df_Species_synom_rename['CAS_SPC_20000_y'] != df_Species_synom_rename['CAS_SPC_20000_x']]
df_Species_synom_rename = df_Species_synom_rename.rename(columns={'CAS_SPC_20000_y':'taxon_id','CAS_SPC_20000_x':'taxon_accepted_id'})
df_Species_synom_rename = df_Species_synom_rename.query("taxon_id!=taxon_accepted_id")

#df_Species_synom_reverse = df_Species_rank_nonnan_for_merge.merge(df_Species_rank_nonnan_valid_for_merge, on="fullcurrname",how='outer')

##species taxon
##1.species valid taxon
df_Species_valid_taxon= pd.DataFrame(df_Species_rank_nonnan_valid,
                                      columns=['CAS_SPC_20000', 'fullcurrname', 'CAS_GEN_2000', 'CAS_REF_NO',
                                               'id', 'STAT_CODE'])
df_Species_valid_taxon = df_Species_valid_taxon.rename(columns={'CAS_SPC_20000':'id', 'fullcurrname':'name', 'CAS_GEN_2000':'parent_id', 'CAS_REF_NO':'reference_id','id':'rank_id','STAT_CODE':'status'})
df_Species_valid_taxon['rank_id'] = '220'


##2.species unvalid curr name(from full species table) taxon
df_Species_rank_nonnan_unvalid =df_Species_rank_nonnan[df_Species_rank_nonnan['STAT_CODE'] != 'Valid']
df_Species_rank_nonnan_unvalid_fulltable= pd.DataFrame(df_Species_rank_nonnan_unvalid,
                                      columns=['CAS_SPC_20000', 'fullorigname', 'CAS_GEN_2000', 'CAS_REF_NO',
                                               'id', 'STAT_CODE'])
df_Species_rank_nonnan_unvalid_fulltable = df_Species_rank_nonnan_unvalid_fulltable.rename(columns={'CAS_SPC_20000':'id', 'fullorigname':'name', 'CAS_GEN_2000':'parent_id', 'CAS_REF_NO':'reference_id','id':'rank_id','STAT_CODE':'status'})
df_Species_rank_nonnan_unvalid_fulltable["parent_id"] = "0"

##3.species valid curr synom name taxon(from valid species table)
df_Species_rank_nonnan_valid_synom = df_Species_rank_nonnan_valid.query("fullcurrname!=fullorigname")
df_Species_rank_nonnan_valid_synom
df_Species_rank_nonnan_valid_synom['CAS_SPC_100000'] = df_Species_rank_nonnan_valid_synom['CAS_SPC_20000'] + 100000
df_Species_rank_nonnan_valid_synom_taxon= pd.DataFrame(df_Species_rank_nonnan_valid_synom,
                                      columns=['CAS_SPC_100000', 'fullorigname', 'CAS_GEN_2000', 'CAS_REF_NO',
                                               'id', 'STAT_CODE'])
df_Species_rank_nonnan_valid_synom_taxon = df_Species_rank_nonnan_valid_synom_taxon.rename(columns={'CAS_SPC_100000':'id', 'fullorigname':'name', 'CAS_GEN_2000':'parent_id', 'CAS_REF_NO':'reference_id','id':'rank_id','STAT_CODE':'status'})
df_Species_rank_nonnan_valid_synom_taxon["parent_id"] = "0"

#c.synom for 3.
df_Species_rank_nonnan_valid_synom_synom = pd.DataFrame(df_Species_rank_nonnan_valid_synom, columns=['CAS_SPC_100000','CAS_SPC_20000'])
df_Species_rank_nonnan_valid_synom_synom = df_Species_rank_nonnan_valid_synom_synom.rename(columns={'CAS_SPC_100000':'taxon_id','CAS_SPC_20000':'taxon_accepted_id'})


##4species without curr name taxon
df_Species_no_curr =  df_Species_rank[df_Species_rank['Curr_GenusID'].isnull()]
df_Species_no_curr_taxon= pd.DataFrame(df_Species_no_curr,
                                      columns=['CAS_SPC_20000', 'fullorigname', 'CAS_GEN_2000', 'CAS_REF_NO',
                                               'id', 'STAT_CODE'])
df_Species_no_curr_taxon = df_Species_no_curr_taxon.rename(columns={'CAS_SPC_20000':'id', 'fullorigname':'name', 'CAS_GEN_2000':'parent_id', 'CAS_REF_NO':'reference_id','id':'rank_id','STAT_CODE':'status'})
df_Species_no_curr_taxon["parent_id"] = df_Species_no_curr_taxon["parent_id"].fillna("0")

###ALL TAXON###
frames = [df_Lineages_taxon,df_Species_valid_taxon,df_Species_rank_nonnan_valid_synom_taxon,df_Species_rank_nonnan_unvalid_fulltable,df_Species_no_curr_taxon,]
df_all_taxon = pd.concat(frames)
df_all_taxon =pd.DataFrame(df_all_taxon,columns=['id','name','rank_id','parent_id','status','reference_id'])


###ALL SYNOM###
synom_frames = [df_Genera_synom, df_Species_synom_rename,df_Species_rank_nonnan_valid_synom_synom]
df_all_synom = pd.concat(synom_frames)
df_all_synom['id'] = [uuid.uuid4() for _ in range(len(df_all_synom.index))]
df_all_synom = df_all_synom.rename(columns={'taxon_accepted_id':'taxon_id_accepted'})
df_all_synom = pd.DataFrame(df_all_synom,columns=['id','taxon_id','taxon_id_accepted'])

###Refereces###
df_References['Author'] = df_References['NAME_1'] + ' ' + df_References['NAME_2']
df_References['pub_time'] = df_References['YR'] + ' ' + df_References['MONTH_DAY']
df_References = df_References.merge(df_Journals,on='JourID')
df_References = pd.DataFrame(df_References,columns=['CAS_REF_NO','TITLE','Author','JOUR_NAME','PP','pub_time'])
df_References = df_References.rename(columns={'CAS_REF_NO':'id','TITLE':'title','Author':'author','JOUR_NAME':'publication','PP':'pages'})

v = cur.execute("select version()")
data = cur.fetchone()
cur.execute("""SELECT table_name FROM information_schema.tables
       WHERE table_schema = 'public'""")
for table in cur.fetchall():
    print(table)
# tmp_df = "df_temp.csv"
# df_all_synom.to_csv(tmp_df, header=False,index = False)
# f = open(tmp_df, 'r')
# cursor = conn.cursor()
#
# cursor.copy_from(f, 'public."Synonym"',columns=['id','taxon_id','taxon_id_accepted'], sep=",")
# conn.commit()

# tmp_df_taxon="df_taxon_temp.csv"
# df_all_taxon.to_csv(tmp_df_taxon, header=False,index = False)
# f = open(tmp_df_taxon, 'r')
# cursor = conn.cursor()
#
# cursor.copy_from(f, 'public."Taxonomy"',columns=['id','name','rank_id','parent_id','status','ref_id'], sep=",")
# conn.commit()


tmp_df_ref="df_ref_temp.csv"
df_References.to_csv(tmp_df_ref, header=False,index = False, sep='\t')
f = open(tmp_df_ref, 'r',encoding='utf8')
cursor = conn.cursor()

cursor.copy_from(f, 'public."Reference"',columns=['id','title','author','publication','pages','pub_time'], sep="\t")
conn.commit()

# rows = zip(df_all_synom.taxon_id, df_all_synom.taxon_accepted_id)
# cur.execute("""CREATE TEMP TABLE codelist(taxon_id INTEGER, taxon_accepted_id INTEGER) ON COMMIT DROP""")
# cur.executemany("""INSERT INTO codelist (taxon_id, taxon_accepted_id) VALUES(%s, %s)""", rows)
#
# cur.execute("""
#     INSERT INTO Synonym(taxon_id,taxon_id_accepted)
#     values (codelist.taxon_id,codelist.taxon_accepted_id);
#     """)

cur.rowcount
conn.commit()
cur.close()
conn.close()