---
title: How to invoke SAP RFC function by external program with nwrfcsdk
date: 2016-12-22 08:42:13
categories: SAP
tags: SAP,RFC,c++,Python
toc: true
---
## cpp invoke nwrfc sdk
> The whole code is in my [gist](https://gist.github.com/mikewolfli/92520c1af3aa2b08c0c0e3d7328808ed)
> nwrfc sdk , you can git download from [here](https://github.com/mikewolfli/sapnwrfcsdk)

### String convert
#### sap uc to wxString
  
``` cpp
 wxString sapucTostring(SAP_UC * s_ucs, int length)
{
  RFC_RC rc;
  RFC_ERROR_INFO errorInfo;

  wxString str;

  if(length==0)
    return wxEmptyString;

  if(length == -1)
     length = strlenU(s_ucs);


  unsigned int utf8Size = length * 2;
  char *utf8 = (char*) malloc(utf8Size + 1);
  utf8[0] = '\0';

  unsigned int resultLen = 0;
  rc = RfcSAPUCToUTF8(s_ucs, length, (RFC_BYTE*) utf8, &utf8Size, &resultLen, &errorInfo);

  int i=0;

  while (rc != RFC_OK) {
    // TODO: throw wrapError
        if(rc==RFC_BUFFER_TOO_SMALL)
        {
            i+=8;
            utf8Size = (length+i) * 2;
            free(utf8);

            utf8 = (char*) malloc(utf8Size + 1);
            utf8[0] = '\0';
            rc = RfcSAPUCToUTF8(s_ucs, length, (RFC_BYTE*) utf8, &utf8Size, &resultLen, &errorInfo);

        }
        else
        {
            errorHandling(rc, cU("sap uc to string"), &errorInfo, NULL);
            return "error";
        }
  }

  str = wxString(utf8,wxConvUTF8);

  free(utf8);

  return str;

}
```

#### wxString to sap uc

``` cpp
SAP_UC * stringTosapuc(wxString &str)
{

  RFC_RC rc;
  SAP_UC *sapuc;
  unsigned int sapucSize, resultLen = 0;

  RFC_ERROR_INFO errorInfo;

  const char *cStr = str.mb_str(wxConvUTF8);

  sapucSize = strlen(cStr) + 1;

  sapuc = mallocU(sapucSize);
  memsetU(sapuc, 0, sapucSize);
  rc = RfcUTF8ToSAPUC((RFC_BYTE*)cStr, strlen(cStr), sapuc, &sapucSize, &resultLen, &errorInfo);

  if (rc != RFC_OK) {
    // FIXME: error handling
    errorHandling(rc, cU("string to sap_uc"), &errorInfo, NULL);
    return cU("error");

  }

   return sapuc;
}
```

#### Establish a pool class to store the dataset from the result of RFC Function

``` cpp

class Str_Line
{
public:
	Str_Line()
	{
		cols = 0; //columns label ptr
		num_cols=0;//column's quantity
	}

	Str_Line(int _col_num)
	{
	    num_cols = _col_num;
        if(_col_num >0)
	        cols = new wxString[num_cols];
	}

	~Str_Line()
	{
		if (cols) delete[] cols;
	}

	wxString *cols;
	int num_cols;
};


class Value_Pool
{
public:
	Value_Pool(int initialLines, bool _dic=false);
	~Value_Pool();
	Str_Line *operator[] (int line)
	{
		return Get_Value(line);
	}
	Str_Line *Get_Value(int lineNo);

	Str_Line *Get_Name()
	{
	    return ptr_name;
	}
	void Delete(int lineNo);

	wxString get_value_by_name(wxString str, Str_Line* p_str);
	wxString get_value_by_index(int i_col, Str_Line* p_str);
	int find_col_name(wxString str);
	int Find_row_value(wxString str, int i_col, int i_start=0);
	wxArrayInt find_row_value_array(wxString str, int i_col, int i_start=0);
	int Get_Same_Count(wxString str, int i_col);


	bool is_dict()
	{
	    return is_dic;
	}

	int GetNumOfRows()
	{
	    return num_rows;
	}

private:
    Str_Line * ptr_name;// store the headers
	Str_Line **ptr_value;// store the values
    bool is_dic;
	int num_rows;

};
```

#### C++ class to communicate with RFC Function

> Because in sap, all rfc function is based on the inner table to run. If you invoke the rfc function , first , you must fill the cases in the import table(inner table), then run the function , at last, get the result in the export table(inner table).

``` cpp

class Rfc_Communication
{
public:
    Rfc_Communication();
    virtual ~Rfc_Communication();

    RFC_FUNCTION_HANDLE Create_Function(wxString function_name,RFC_FUNCTION_DESC_HANDLE& funhandle_desc);
    RFC_RC fillFunctionParameter(RFC_FUNCTION_DESC_HANDLE funcDesc, RFC_FUNCTION_HANDLE container, wxString v_name, Value_Pool * v_value);//list cases fill
    RFC_RC fillFunctionParameter(RFC_FUNCTION_DESC_HANDLE funcDesc, RFC_FUNCTION_HANDLE container, wxString v_name, wxString s_value);//single case fill
    RFC_RC RunFunction(RFC_FUNCTION_HANDLE fun_handle);
    RFC_RC DestroyFunction(RFC_FUNCTION_HANDLE fun_handle);
    Value_Pool* GetResult(wxString result_name, RFC_FUNCTION_DESC_HANDLE fun_handle_desc, RFC_FUNCTION_HANDLE fun_handle);
    RFC_RC rfc_connect(); 
    void rfc_closed();
    bool rfc_check_connect();

    wxString str_result;

protected:
private:

    RFC_CONNECTION_HANDLE connection;
    RFC_ERROR_INFO errorInfo;

    SAP_UC* fillString(wxString str);
    wxString wrapString(SAP_UC * uc,int length =-1, bool rstrip=false);

    RFC_RC lookupMetaData(wxString function_name,RFC_FUNCTION_DESC_HANDLE &funhandle_desc);
    RFC_RC fillVariable(RFCTYPE typ, RFC_FUNCTION_HANDLE container, SAP_UC* cName, Value_Pool * v_value, wxString str, RFC_TYPE_DESC_HANDLE typeDesc);
    RFC_RC fillStructureField(RFC_TYPE_DESC_HANDLE typeDesc, RFC_STRUCTURE_HANDLE container, SAP_UC * name, wxString s_value);
    RFC_RC fillTable(RFC_TYPE_DESC_HANDLE typeDesc, RFC_TABLE_HANDLE container, Value_Pool* value);
    RFC_RC fillField(RFCTYPE typ, DATA_CONTAINER_HANDLE container, SAP_UC* name, wxString s_value);

    Value_Pool* wrapResult(RFC_FUNCTION_DESC_HANDLE functionDescHandle, RFC_FUNCTION_HANDLE functionHandle, wxString varial_name, bool rstrip=false);
    void wrapStructure(RFC_TYPE_DESC_HANDLE typeDesc, RFC_STRUCTURE_HANDLE structHandle, Str_Line* line_value=NULL,bool _withname=false, Str_Line* line_name=NULL, bool rstrip=false);
    Value_Pool* wrapVariable(RFCTYPE typ, RFC_FUNCTION_HANDLE functionHandle, SAP_UC* cName, unsigned int cLen, RFC_TYPE_DESC_HANDLE typeDesc, bool rstrip=false);
    wxString wrapField(RFCTYPE typ, RFC_STRUCTURE_HANDLE functionHandle, SAP_UC* cName, unsigned int cLen, bool rstrip=false);

};

```

#### sample - how to use this class to invoke the rfc function

##### this is rfc function def

> Function id : ZAP_PS_MATERIAL_INFO
> import:  IT_CE_MARA

field id|	type|	length|	decimal|	description
--------|-------|---------|--------|----------------
MATNR   |CHAR	|18		  |        |Material Number
WERKS	|CHAR	|4		  |        |Plant

>         CE_SPRAS

field id|	type|	length|	decimal|	description
--------|-------|---------|--------|----------------
Language|CHAR   |	1	  |        |Language Key

> export: OT_CE_MARA


field id|	type|	length|	decimal|	description
--------|-------|---------|--------|----------------
MATNR|CHAR|18|0|Material Number
MAKTG|CHAR|40|0|Material description in upper case for matchcodes
MAKTX|CHAR|40|0|Material Description (Short Text)
SPRAS|LANG|1|0|Language Key
BRGEW|QUAN|13|3|Gross Weight
MEINS|UNIT|3|0|Base Unit of Measure
MTART|CHAR|4|0|Material Type
NORMT|CHAR|18|0|Industry Standard Description (such as ANSI or ISO)
BISMT|CHAR|18|0|Old material number
ZEINR|CHAR|22|0|Document number (without document management system)
GROES|CHAR|32|0|Size/dimensions
LGFSB|CHAR|4|0|Default storage location for external procurement
LGPRO|CHAR|4|0|Issue Storage Location
DISPO|CHAR|3|0|MRP Controller (Materials Planner)
SBDKZ|CHAR|1|0|Dependent requirements ind. for individual and coll. reqmts
FEVOR|CHAR|3|0|Production scheduler
SOBSK|CHAR|2|0|Special Procurement Type for Costing
BESKZ|CHAR|1|0|Procurement Type
SOBSL|CHAR|2|0|Special procurement type
MATGR|CHAR|20|0|Group of Materials for Transition Matrix
MFRGR|CHAR|||Material freight group
WERKS|CHAR|4|0|Plant
VPRSV|CHAR|1|0|Price control indicator
BWTAR|CHAR|10|0|Valuation Type
BWKEY|CHAR|4|0|Valuation Area
BKLAS|CHAR|4|0|Valuation Class
TDLINE|CHAR|255|0|Material master Basic Data  Text

> As above, the IT_CE_MARA, CE_SPRAS, OT_CE_MARA are structure. 


> Invoke code

``` cpp
void rfctestDialog::OnButton1Click(wxCommandEvent& event)
{
    if(!sap_conn->rfc_check_connect())
        sap_conn->rfc_connect();

    Value_Pool* mat_value=new Value_Pool(1, true); // this is filled innner table

    Str_Line * line= mat_value->Get_Name();

    line->cols= new wxString[2];
    line->num_cols = 2;
    wxString str = "MATNR";

    line->cols[0] = str;

    str = "WERKS";
    line->cols[1] = str;

    line = mat_value->Get_Value(0);
    line->num_cols = 2;

    line->cols = new wxString[2];

    str = "330040240";
  //  str = "200000051";
    line->cols[0] = str;

    str = "2101";
    line->cols[1] = str;
    wxString s_lang = "1";


    Value_Pool * pool_result;


    RFC_FUNCTION_DESC_HANDLE fun_handle_desc;
    RFC_FUNCTION_HANDLE fun_handle;


    fun_handle = sap_conn->Create_Function(wxT("ZAP_PS_MATERIAL_INFO"),fun_handle_desc);
    sap_conn->fillFunctionParameter(fun_handle_desc,fun_handle,wxT("IT_CE_MARA"),mat_value);//fill query table 
    sap_conn->RunFunction(fun_handle);
    pool_result = sap_conn->GetResult(wxT("OT_CE_MARA"),fun_handle_desc,fun_handle);//get result table

    sap_conn->DestroyFunction(fun_handle);

    if(pool_result)
    {
        int i_row = pool_result->GetNumOfRows();
        str.Empty();

        Str_Line* line_head= pool_result->Get_Name();

        for(int i=0; i<i_row; i++)
        {
            Str_Line * line = pool_result->Get_Value(i);

            int i_col = line->num_cols;

            for(int j=0; j<i_col; j++)
            {
                str = str+line_head->cols[j]+wxT(":")+line->cols[j]+wxT("\n");
            }
        }
    }

    tc_result->SetValue(str);

}
```

## Python invoke RFC Function
> This must install the pyRFC.
> How to intall it , you can according to [link](http://sap.github.io/PyRFC/)
> How to invoke it :

``` Python
...
import pyrfc
...
        
    def check_in_sap(self):
        self.nstd_mat_list=[]
        self.nstd_app_id=''
        self.hibe_mats=[]
        
        '''
        read the user and login parameters from a cfg file
        '''
        logger.info("logining in SAP...")
        config = ConfigParser()
        config.read('sapnwrfc.cfg')
        para_conn  = config._sections['connection']
        para_conn['user'] = base64.b64decode(para_conn['user']).decode()
        para_conn['passwd'] = base64.b64decode(para_conn['passwd']).decode()
        mats = self.mat_items.keys()
        
        try:
            conn = pyrfc.Connection(**para_conn)
            
            imp = []
            for mat in mats: #loop to fill the query list 
                line = dict(MATNR=mat, WERKS='2101')
                imp.append(line)
            
            logger.info("正在调用RFC函数...")
            result = conn.call('ZAP_PS_MATERIAL_INFO', IT_CE_MARA=imp, CE_SPRAS='1')
            
            std_mats=[]
            for re in result['OT_CE_MARA']: #loop to read the result line
                std_mats.append(re['MATNR'])
                
                if re['BKLAS']=='3030' and re['MATNR'] not in self.hibe_mats:
                    self.hibe_mats.append(re['MATNR'])
                
            for mat in mats:
                if mat not in std_mats:
                    logger.info("标记非标物料:"+mat)
                    self.nstd_mat_list.append(mat)
                    self.mark_nstd_mat(mat, True)
                else:
                    self.mark_nstd_mat(mat, False)
                    
            logger.info("非标物料确认完成，共计"+str(len(self.nstd_mat_list))+"个非标物料。")
            
        except pyrfc.CommunicationError:
            logger.error("无法连接服务器")
            return -1
        except pyrfc.LogonError:
            logger.error("无法登陆，帐户密码错误！")
            return -1
        except (pyrfc.ABAPApplicationError, pyrfc.ABAPRuntimeError):
            logger.error("函数执行错误。")
            return -1
        
        conn.close()
                   
        return len(self.nstd_mat_list)
```

## Reference
1. [node-rfc: https://github.com/SAP/node-rfc](https://github.com/SAP/node-rfc)
2. [pyRFC: https://github.com/SAP/PyRFC](https://github.com/SAP/PyRFC)







