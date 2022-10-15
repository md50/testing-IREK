-- $Id: resultsNotFlagAsSentToHIS.sql 12506 2022-09-19 14:04:38Z jzajdel $
select
	gp_ord_extnum as EXTNUM,
	gp_ord_ordnum as Casenum,
	gp_otst_originexttest as TestId,
	to_char(GP_REP_SDATE ,'YYYY-MM-DD HH24:Mi:ss') as SIGNDT
from
	gp_order join gp_otest on gp_otst_ordid = gp_ord_recid and gp_otst_panelid is null and gp_otst_status = 'F' and gp_ord_extnum is not null
	join gs_test on gp_otst_code = gs_tst_code and gs_tst_act = 'Y' and GS_TST_REPTOEXTSYS = 'Y'
	join gp_reqinterp on gp_reqi_recid = gp_otst_reqiid
	join gp_report on GP_REP_REQINTERPID = gp_reqi_recid and GP_REP_ACTUAL = 'Y'
	join gi_testscc on gp_ord_ordnum = gi_ts_ordnum and gi_ts_sys = 'GIS' and gi_ts_test = nvl(gp_otst_originexttest,gp_otst_code)
	left join gi_testhis on gi_ts_corrid = gi_th_corrid and gi_th_dest = 'HIS.TEK'
where
	gi_th_ordnum is null or bitand(gi_th_flag,262144) = 0
	and GP_REP_SDATE < SYSDATE - interval '5' minute
	and GP_REP_SDATE > SYSDATE - 7 
order by
	SIGNDT, EXTNUM, TestId;
exit;