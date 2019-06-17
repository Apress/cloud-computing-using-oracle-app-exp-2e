--S1A-- COMPANY TABLE
CREATE TABLE GL_Company
(Cocode NUMBER, Coname VARCHAR2(50), Coaddress varchar2(100), Cophone varchar2(15), Cofax varchar2(15), Cocity varchar2(15), Cozip varchar2(15), Cocurrency varchar2(15), CONSTRAINT GL_COMPANY_PK PRIMARY KEY (Cocode) ENABLE);

--S1B-- COMPANY TABLE SEQUENCE
CREATE SEQUENCE GL_COMPANY_SEQ;

--S2-- COMPANY FISCAL YEAR TABLE
CREATE TABLE GL_Fiscal_Year
(Cocode NUMBER Constraint fk_GL_fiscal_year References GL_Company (Cocode), Coyear number(4), Comonthid number(2), Comonthname varchar2(9), Pfrom date, Pto date, Initial_Year number(1), Year_Closed number(1), Month_Closed number(1), TYE_Executed date, CONSTRAINT GL_FISCAL_YEAR_PK PRIMARY KEY (Cocode,Coyear,Comonthid) ENABLE);

--S3A-- VOUCHER TYPES TABLE
CREATE TABLE GL_Voucher
(Vchcode NUMBER, Vchtype VARCHAR2(6), Vchtitle varchar2(30), Vchnature number(1), CONSTRAINT GL_VOUCHER_PK PRIMARY KEY (Vchcode) ENABLE);

--S3B-- VOUCHER TABLE SEQUENCE
CREATE SEQUENCE GL_VOUCHER_SEQ;

--S4-- COST CENTERS TABLE
CREATE TABLE GL_Cost_Center
(Cocode NUMBER Constraint fk_gl_cost_center References GL_Company (Cocode), Cccode varchar2(5), Cctitle varchar2(25), Cclevel number(1), CONSTRAINT GL_COST_CENTER_PK PRIMARY KEY (Cocode,Cccode) ENABLE);

--S5-- CHART OF ACCOUNT TABLE
CREATE TABLE GL_COA
(Cocode NUMBER Constraint fk_gl_coa References GL_Company (Cocode), COAcode varchar2(11), COAtitle varchar2(50), COAlevel number(1), COAnature varchar2(11), COAtype varchar2(11), Cccode varchar2(5), CONSTRAINT GL_COA_PK PRIMARY KEY (Cocode,COAcode) ENABLE);

--S6A-- TRANSACTION MASTER TABLE
create table GL_TRAN_MASTER
(Tran_No number, Cocode number Constraint fk_gl_tran_master1 References GL_Company (Cocode) NOT NULL, Coyear number(4) NOT NULL, comonthid number(2) NOT NULL, vchcode number Constraint fk_gl_tran_master2 References GL_Voucher (vchcode) NOT NULL, vchno number(10) NOT NULL, vchdate date NOT NULL, vchdescription varchar2(150) NOT NULL, createdby varchar2(10) NOT NULL, createdon date NOT NULL, vchverified varchar2(1) NOT NULL, vchposted varchar2(1) NOT NULL, closing number(1) NOT NULL, constraint pk_gl_tran_master PRIMARY KEY (tran_no), constraint fk_gl_tran_master3 Foreign Key (Cocode,Coyear,Comonthid) References GL_Fiscal_Year);

CREATE OR REPLACE EDITIONABLE TRIGGER  "GL_TRAN_MASTER_BI" 
  BEFORE insert on "GL_TRAN_MASTER" for each row
declare
  tran_no number;
begin
  if :new.tran_no is null then
    select gl_tran_master_seq.nextval 
      into tran_no 
      from dual;
    :new.tran_no := tran_no;
  end if;
end;
/
ALTER TRIGGER  "GL_TRAN_MASTER_BI" ENABLE;
/


--S6B-- TRANSACTION DETAIL TABLE
create table GL_TRAN_DETAIL
(Line_No number, Tran_No number NOT NULL, Cocode number Constraint fk_gl_tran_detail1 References GL_Company (Cocode) NOT NULL, coacode varchar2(11) NOT NULL, cccode varchar2(5), vchdescription varchar2(150) NOT NULL, vchdr number(15,2) NOT NULL, vchcr number(15,2) NOT NULL, vchreference varchar2(25), reconciled number(1) NOT NULL, constraint pk_gl_tran_detail Primary Key (line_no), constraint fk_gl_tran_detail3 Foreign Key (cocode,cccode) References GL_Cost_Center, constraint fk_gl_tran_detail4 Foreign Key (cocode,coacode) References GL_COA);


CREATE OR REPLACE EDITIONABLE TRIGGER  "GL_TRAN_DETAIL_BI" 
  BEFORE insert on "GL_TRAN_DETAIL" for each row
declare
  line_no number;
begin
  if :new.line_no is null then
    select gl_tran_detail_seq.nextval 
      into line_no 
      from dual;
    :new.line_no := line_no;
  end if;
end;
/
ALTER TRIGGER  "GL_TRAN_DETAIL_BI" ENABLE;
/


--S6C-- ADD FOREIGN KEY
ALTER TABLE GL_TRAN_DETAIL ADD CONSTRAINT FK_gl_TRAN_DETAIL2 FOREIGN KEY (TRAN_NO) REFERENCES GL_TRAN_MASTER(TRAN_NO) ON DELETE CASCADE ENABLE;

--S6D-- TRANSACTION TABLE SEQUENCE
CREATE SEQUENCE GL_TRAN_MASTER_SEQ MINVALUE 1 START WITH 1 INCREMENT BY 1 CACHE 20;
CREATE SEQUENCE GL_TRAN_DETAIL_SEQ MINVALUE 1 START WITH 1 INCREMENT BY 1 CACHE 20;

--S6E-- TRIGGER TO POPULATE DEFAULT COST CENTER CODE FROM CHART OF ACCOUNT (IF LEFT NULL IN VOUCHER)

CREATE OR REPLACE TRIGGER  "TRAN_DETAIL_GET_COST_CENTER" 
  before insert or update on GL_TRAN_DETAIL for each row
declare
  Vcccode varchar2(5);
begin
  if :new.cccode is null then
    select cccode
    into Vcccode
    from GL_COA
    where cocode = :new.cocode and coacode = :new.coacode;
    :new.cccode := Vcccode; 
  end if;
end;

/
ALTER TRIGGER  "TRAN_DETAIL_GET_COST_CENTER" ENABLE
/


--S7-- TRIAL BALANCE REPORT TABLE
create table GL_TRIAL_BALANCE
(coacode varchar2(11), coatitle varchar2(50), coalevel number(1), opendr number(15,2), opencr number(15,2), activitydr number(15,2), activitycr number(15,2), closingdr number(15,2), closingcr number(15,2), coname varchar2(50), tbdate date, fromaccount varchar2(11), toaccount varchar2(11), cccode varchar2(5), cctitle varchar2(25), reportlevel number(1), userid varchar2(50), grand_total number(1));

--S8-- BANK OPENING OUTSTANDINGS
create table GL_BANKS_OS
(sr_no number, Cocode number Constraint fk_gl_banks_os1 References GL_Company (Cocode) NOT NULL, coacode varchar2(11) NOT NULL, remarks varchar2(50) NOT NULL, vchdr number(15,2) NOT NULL, vchcr number(15,2) NOT NULL, reconciled number(1) NOT NULL, constraint pk_gl_banks_os Primary Key (sr_no), constraint fk_gl_banks_os2 Foreign Key (cocode,coacode) References GL_COA);

CREATE SEQUENCE GL_BANKS_OS_SEQ MINVALUE 1 START WITH 1 INCREMENT BY 1 CACHE 20;


CREATE OR REPLACE EDITIONABLE TRIGGER  "GL_BANKS_OS_BI" 
  BEFORE insert on "GL_BANKS_OS" for each row
declare
  sr_no number;
begin
  if :new.sr_no is null then
    select gl_banks_os_seq.nextval 
      into sr_no 
      from dual;
    :new.sr_no := sr_no;
  end if;
end;
/
ALTER TRIGGER  "GL_BANKS_OS_BI" ENABLE;
/





--S9-- BANK RECONCILIATION REPORT
create table GL_RECONCILE_REPORT
(srno number, userid varchar2(50), coname varchar2(50), reportdate date, coacode varchar2(11), coatitle varchar2(50), monthyear varchar2(14), vchdate date, Vchtype VARCHAR2(6), vchno number(10), vchdescription varchar2(150), vchreference varchar2(25), amount number(15,2));   

--S10-- BUDGET ALLOCATION

create table GL_BUDGET (cocode number Constraint fk_gl_budget1 References GL_Company (Cocode) NOT NULL, coyear number(4), coacode varchar2(11) NOT NULL, coanature varchar2(11) NOT NULL, cccode varchar2(5), budget_amount1 number(15,2), budget_amount2 number(15,2), budget_amount3 number(15,2), budget_amount4 number(15,2), budget_amount5 number(15,2), 
budget_amount6 number(15,2), budget_amount7 number(15,2), budget_amount8 number(15,2), budget_amount9 number(15,2), budget_amount10 number(15,2), budget_amount11 number(15,2), 
budget_amount12 number(15,2), criterion number(1), constraint fk_gl_budget2 Foreign Key (cocode,coacode) References GL_COA);

--S11-- BUDGET REPORT TABLE
create table GL_BUDGET_REPORT
(coacode varchar2(11), coatitle varchar2(50), budget number(15,2), actual number(15,2), variance number(15,2), percent number(7,2), status varchar2(1), userid varchar2(50), grand_total number(1), coname varchar2(50), AccountFrom varchar2(11), AccountTo varchar2(11), MonthFrom varchar2(9), MonthTo varchar2(9), PrintedOn timestamp);

--S12-- FINANCIAL STATEMENTS SETUP TABLE
create table GL_FS_SETUP
(cocode NUMBER, reportcode varchar2(4), reporttitle varchar2(50), fsaccount varchar2(50), AccountFrom varchar2(11), AccountTo varchar2(11), CONSTRAINT GL_FS_SETUP_PK PRIMARY KEY (cocode,reportcode,fsaccount) ENABLE);

--S13-- FINANCIAL STATEMENTS REPORT TABLE
create table GL_FS_REPORT
(reportcode varchar2(4), reporttitle varchar2(50), srno NUMBER, fsaccount varchar2(50), currentbalance number(15,2), previousbalance number(15,2), percent number(7,2), userid varchar2(50), coname varchar2(50), coyear number(4), comonthname varchar2(9), calculation number(1), netvalue number(1), notes number(1), notescode varchar2(11), notestitle varchar2(50), heading number(1));

--S14A-- SEGMENTS FOR APPLICATION ACCESS
create table GL_SEGMENTS
(segmentID NUMBER, segmentTitle varchar2(50), segmentParent number, segmentType varchar2(4), pageID number(4), itemRole varchar2(10), CONSTRAINT GL_SEGMENTS_PK PRIMARY KEY (segmentID) ENABLE);

--S14B--
CREATE SEQUENCE GL_SEGMENTS_SEQ MINVALUE 1 START WITH 1 INCREMENT BY 1 CACHE 20;


--S15A-- USER GROUPS MASTER TABLE
create table GL_GROUPS_MASTER
(groupID NUMBER(4), groupTitle varchar2(25), CONSTRAINT GL_GROUPS_PK PRIMARY KEY (groupID) ENABLE); 

--S15B-- USER GROUPS DETAIL TABLE
create table GL_GROUPS_DETAIL
(groupID NUMBER(4) Constraint fk_gl_Group_Detail References GL_GROUPS_MASTER (groupID), segmentID NUMBER Constraint fk_gl_user_groups References GL_SEGMENTS (segmentID), segmentParent number, segmentType varchar2(4), pageID number(4), itemRole varchar2(10), allow_access varchar2(1));

--S16-- APPLICATION USERS TABLE
create table GL_USERS
(userID varchar2(50), cocode number Constraint fk_gl_users References GL_Company (Cocode), coyear number(4), comonthid number(2), groupID number(4) Constraint fk_gl_users2 References GL_GROUPS_MASTER (groupID), password varchar2(4000), admin varchar2(1), CONSTRAINT GL_USERS_PK PRIMARY KEY (userID) ENABLE);


--S17-- APPLICATION DASHBOARD
create table GL_DASHBOARD
(srno NUMBER, accountTitle varchar2(50), currentYear number(15,2), previousYear number(15,2), userid varchar2(50), ratioTitle varchar2(50), current_year number(15,2), previous_year number(15,2));

--S18-- APPLICATION FEEDBACK
create table GL_FEEDBACK
(feedbackID NUMBER, TS timestamp default sysdate, custName varchar2(50), custEmail varchar2(100), custFeedback varchar2(4000), CONSTRAINT GL_FEEDBACK_PK PRIMARY KEY (feedbackID) ENABLE);

CREATE SEQUENCE GL_FEEDBACK_SEQ;
