<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: rebuildMessage.xsl 12177 2022-07-21 11:02:57Z mzelazko $ -->
<xsl:stylesheet version="2.0" xmlns:rtf="java:com.scc.smx.utils.RtfConverter" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:cmn="http://www.softcomputer.com/COMMON/RROutService" xmlns:saxon="http://saxon.sf.net/" exclude-result-prefixes="#all">
	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="no"/>
	<xsl:strip-space elements="*"/>
	<!--
		****************************************************************************
		*** Includes.
		****************************************************************************
	-->
	<xsl:include href="${env.GUIDICT}/eis/xslt/commonFunction.xslt"/>
	<xsl:include href="${env.GUIDICT}/eis/xslt/cmn_tagMapping.xslt"/>
	<!--<xsl:include href="C:\SVN\eis\xslt\commonFunction.xslt"/>
	<xsl:include href="C:\SVN\eis\xslt\cmn_tagMapping.xslt"/>-->
	<!--
		****************************************************************************
		*** String parameters.
		****************************************************************************
	-->
	<xsl:param name="rtfSymbolsTable"/>
	<xsl:param name="txtSymbolsTable"/>
	<xsl:param name="blockDefaultResults" as="xs:string">-</xsl:param>
	<xsl:param name="blockedPromptTestFor" as="xs:string">-</xsl:param>
	<xsl:param name="includeChangeReasonRMOD" as="xs:string">-</xsl:param>
	<xsl:param name="returnInfoForEvents" as="xs:string">TEST_RELEASED,TEST_RESEND,ORDER_RESEND</xsl:param>
	<xsl:param name="dropCancelledResComments" as="xs:string">-</xsl:param>
	<xsl:param name="blockPendingsTechnologies" as="xs:string">-</xsl:param>
	<xsl:param name="readTagLayoutDMOD" select="'-'"/>
	<xsl:param name="readTagLayoutRMOD" select="'-'"/>
	<xsl:param name="readTagLayoutMODCOT" select="'-'"/>
	<xsl:param name="readTagLayoutMODCOM" select="'-'"/>
	<xsl:param name="readTagLayoutTCANC" select="'-'"/>
	<xsl:param name="readTagLayoutCALLED" select="'-'"/>
	<xsl:param name="readTagLayoutM_CALLED" select="'-'"/>
	<xsl:param name="extendedNteMatch">false</xsl:param>
	<xsl:param name="startShadowReportDelimiter">[%1 _start]</xsl:param>
	<xsl:param name="endShadowReportDelimiter">[%1 _end]</xsl:param>
	<!--
		****************************************************************************
		***  Boolean parameters.
		****************************************************************************
	-->
	<xsl:param name="sendAllRMODs" as="xs:string">false</xsl:param>
	<xsl:param name="sendDmodComment" as="xs:string">true</xsl:param>
	<xsl:param name="sendModcomComment" as="xs:string">true</xsl:param>
	<xsl:param name="dropResultsWithoutPathologistReview" as="xs:string">-</xsl:param>
	<xsl:param name="textForELSG">Interpreted by:</xsl:param>
	<!--
		Call parameters.
	-->
	<!--
		'enableExtendedCalledMode' - to control sending CALLED|NTE and/or M_CALLED|NTE segments under result OBX when the call was placed for all the components/results
	> acceptable values:
	- true - the system shall always generate CALLED|NTE and/or M_CALLED|NTE under result OBX, additionally OBX|SH (TestHeader) level CALLED NTE shall NOT be created,
	- false - the system shall prevent generating  CALLED|NTE and/or M_CALLED|NTE under result OBX in the described case (all components/results are called), additionally OBX|SH (TestHeader) level CALLED NTE shall be created,
	-->
	<xsl:param name="enableExtendedCalledMode">true</xsl:param>
	<!--
		'callInfoExcludeCriteria' - to control call qualification logic,
		> acceptable values:
		- "-"/"none" - everything qualifies
		- "cancelled" – cancelled tests are ignored (where observationResultStatus=Cancelled)
		- "autodefault" – auto defaulted tests are ignored (where observationMethod=DEFAULT)
	-->
	<xsl:param name="callInfoExcludeCriteria">cancelled,autodefault</xsl:param>
	<!--
		'readTagsFormat' - contains list of TAGS that should be read from SoftLAB setup,
		> acceptable values for Call logic:
		- CALLED
		- M_CALLED
	-->
	<xsl:param name="readTagsFormat">-</xsl:param>
	<!--
		'sendHistoricalCallInfo' - support historical Called obx-es (M_CALLED NTE),
	    > acceptable values:
		- "true"
		- "false"
	-->
	<xsl:param name="sendHistoricalCallInfo">false</xsl:param>
	<!--
		'valueForCalls' - to send Reason or Message in NTE[3],
		> acceptable values:
		- "reason"
		- "message"
	-->
	<xsl:param name="valueForCalls">message</xsl:param>
	<xsl:param name="maxTry" select="'430'"/>
	<xsl:param name="waitForParentHIS" select="'false'"/>
	<!--
		****************************************************************************
		*** Variables.
		****************************************************************************
	-->
	<!--ISS-EIS-3194IT - delaying HL7 formatting until the main test's GI entry is available where waitForParentHIS = 'false'-->
	<xsl:variable name="try" select="if (string(//Event/msg/muti)) then replace((//Event/msg/muti)[1], '(.+?:){2}', '') else replace((//msg/muti)[1], '(.+?:){2}', '')" />
	<xsl:variable name="maxTryFirstVal">
		<xsl:value-of select="if (contains($maxTry, ':')) then substring-before($maxTry, ':') else $maxTry"/>
	</xsl:variable>
	<xsl:variable name="maxTrySecondVal">
		<xsl:value-of select="if (contains($maxTry, ':')) then substring-after($maxTry, ':') else '10'"/>
	</xsl:variable>
	<!--  		Variables which controls date format.  	-->
	<xsl:variable name="dtFormat" select="'${env.DT_FORMAT}'"/>
	<xsl:variable name="dtPattern" as="xs:string">
		<xsl:choose>
			<xsl:when test="$dtFormat = ('0','3','6')">
				<xsl:value-of select="'[M,2]/[D,2]/[Y]'"/>
			</xsl:when>
			<xsl:when test="$dtFormat = ('2','5','8')">
				<xsl:value-of select="'[D,2]/[M,2]/[Y]'"/>
			</xsl:when>
			<xsl:when test="$dtFormat = ('1','4','7')">
				<xsl:value-of select="'[Y]/[M,2]/[D,2]'"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="'[M,2]/[D,2]/[Y]'"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="timeFormat" select="'[H]:[m01]'" />
	<!--
  		Return extra data in MOM response, i.e. OBX dropped because of 'Pending', etc.
  	-->
	<xsl:variable name="generateInfoData" as="xs:boolean" select="cmn:matchPatern($event, $returnInfoForEvents, ',')"/>
	<!--
		Unique character  - required for removeFrontEndCarriageReturns.
	-->
	<xsl:variable name="delim" select="'&#254;'"/>
	<!--
		Current MOM event.
	-->
	<xsl:variable name="event" as="xs:string" select="/Message/Event/msg/eventCode"/>
	<!--
		Indicates if current transaction is the MICRO transaction.
	-->
	<xsl:variable name="isMicroTransaction" as="xs:boolean" select="/Message/Event/msg/attributes[name = 'TIDS']/value = 'MIC'"/>
	<!--
		Called variables
	-->
	<xsl:variable name="mess" select="//Message" />
	<!--
		'messCall' variable contains the patch to all CallInfo obx-es.
		'CallInfo' obx-es contain all called test from LAB/CSM etc.
		These obx-es are created in RDC by CSM canonical (csm2canonical.xslt) based on 'getCallDetailsResponse' response.
		CSM canonical should return all current and historical 'CallInfo' obx-es.
		These obx-es should be sorted by date in canonical (latest/newest at the top).
	-->
	<xsl:variable name="messCall" select="$mess//obrLevel/obxLevel/obx[obxType='CallInfo']"/>
	<!--
		'messNotHistoricalCall' variable contains the patch to not historical Called obx-es.
		All current called obx-es must contain 'history' set to 'false' (<history>false</history>).
		These obx-es should be sorted by date in canonical (latest/newest at the top).
	-->
	<xsl:variable name="messNotHistoricalCall" select="$mess//obrLevel/obxLevel/obx[obxType='CallInfo'][history='false' or not(history)]"/>
	<!--
		'isCancelledTestComponents' variable checks the existence of the cancelled tests
	-->
	<xsl:variable name="isCancelledTestComponents" as="xs:boolean" select="$mess//obrLevel/obxLevel/obx[results/reportable = 'true' and results/toHIS = 'true' and history='false' 
																                                           and matches(obxType, 'Result|Interpretation|PromptTest')]/observationResultStatus = 'Cancelled'"/>
	<!--
		'isAutoDefaultTestComponents' variable checks the existence of the auto default tests
	-->
	<xsl:variable name="isAutoDefaultTestComponents" as="xs:boolean" select="$mess//obrLevel/obxLevel/obx[results/reportable = 'true' and results/toHIS = 'true' and history='false' 
																											 and matches(obxType, 'Result|Interpretation|PromptTest')]/observationMethod = 'DEFAULT'"/>
	<!--
		'countTestComponents' variable contains total number of 'Result', 'Interpretation' and 'PromptTest' obx-es.
	-->
	<xsl:variable name="countTestComponents">
		<xsl:choose>
			<xsl:when test="matches($callInfoExcludeCriteria, '-|none') or not(string($callInfoExcludeCriteria))">
				<xsl:value-of select="count($mess//obrLevel/obxLevel/obx[((results/callable='true') or not(string(results/callable))) and results/reportable = 'true' and results/toHIS = 'true' and history='false' and matches(obxType, 'Result|Interpretation|PromptTest')])"/>
			</xsl:when>
			<!-- cancelled test components: -->
			<xsl:when test="matches($callInfoExcludeCriteria, 'cancelled') and not(matches($callInfoExcludeCriteria, 'autodefault')) 
									and $isCancelledTestComponents">
				<xsl:value-of select="count($mess//obrLevel/obxLevel/obx[results/reportable = 'true' and results/toHIS = 'true' and history='false' and matches(obxType, 'Result|Interpretation|PromptTest')
																	     and not(matches(observationResultStatus, 'Cancelled'))])"/>
			</xsl:when>
			<!-- autodefault test components: -->
			<xsl:when test="matches($callInfoExcludeCriteria, 'autodefault') and not(matches($callInfoExcludeCriteria, 'cancelled')) 
									and $isAutoDefaultTestComponents">
				<xsl:value-of select="count($mess//obrLevel/obxLevel/obx[results/reportable = 'true' and results/toHIS = 'true' and history='false' and matches(obxType, 'Result|Interpretation|PromptTest')
																		 and observationMethod != 'DEFAULT'])"/>
			</xsl:when>
			<!-- cancelled & autodefault test components: -->
			<xsl:when test="matches($callInfoExcludeCriteria, 'cancelled') and matches($callInfoExcludeCriteria, 'autodefault') 
							and ($isCancelledTestComponents or $isAutoDefaultTestComponents)">
				<xsl:value-of select="count($mess//obrLevel/obxLevel/obx[results/reportable = 'true' and results/toHIS = 'true' and history='false' and matches(obxType, 'Result|Interpretation|PromptTest')
																		 and (($isCancelledTestComponents and (not($isAutoDefaultTestComponents)) and not(matches(observationResultStatus, 'Cancelled')))
																		 or ($isCancelledTestComponents and ($isAutoDefaultTestComponents) and not(matches(observationResultStatus, 'Cancelled')) 
																		 and observationMethod != 'DEFAULT')
																		 or (not($isCancelledTestComponents) and (isAutoDefaultTestComponents) and observationMethod != 'DEFAULT'))])"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="count($mess//obrLevel/obxLevel/obx[results/reportable = 'true' and results/toHIS = 'true' and history='false' and matches(obxType, 'Result|Interpretation|PromptTest')])"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<!--
		'countCurrentCalledTests' variable contains number of not historical Called obx-es.
	-->
	<xsl:variable name="countCurrentCalledTests"  select="count($mess//obrLevel/obxLevel/obx[(history='false' or not(history)) and obxType='CallInfo'])" />
	<!--
		'countHistoricalCurrentTests' variable contains number of historical Called obx-es.
		These historical obx-es must be located under the current obx and such obx-es should be sorted by date in canonical (latest/newest at the top).
	-->
	<xsl:variable name="countHistoricalCurrentTests"  select="count($mess//obrLevel/obxLevel/obx[history='true' and obxType='CallInfo'])" />
	<!--
		'allTests' variable contains Observation Id of 'Result', 'Interpretation' and 'PromptTest' obx-es.
	-->
    <xsl:variable name="allTests" as="item()*">
		<xsl:choose>
			<xsl:when test="matches($callInfoExcludeCriteria, '-|none') or not(string($callInfoExcludeCriteria))">
				<xsl:for-each select="$mess//obrLevel/obxLevel/obx[((results/callable='true') or not(string(results/callable))) and results/reportable = 'true' and results/toHIS = 'true' and history='false' and matches(obxType, 'Result|Interpretation|PromptTest')]/observationId">
					<xsl:value-of select="."/>
				</xsl:for-each>
			</xsl:when>
			<xsl:when test="matches($callInfoExcludeCriteria, 'cancelled') and not(matches($callInfoExcludeCriteria, 'autodefault')) 
									and $isCancelledTestComponents">
				<xsl:for-each select="$mess//obrLevel/obxLevel/obx[results/reportable = 'true' and results/toHIS = 'true' and history='false' and matches(obxType, 'Result|Interpretation|PromptTest')
																   and not(matches(observationResultStatus, 'Cancelled'))]/observationId">
									<xsl:value-of select="."/>
				</xsl:for-each>
			</xsl:when>
			<xsl:when test="matches($callInfoExcludeCriteria, 'autodefault') and not(matches($callInfoExcludeCriteria, 'cancelled')) 
									and $isAutoDefaultTestComponents">
				<xsl:for-each select="$mess//obrLevel/obxLevel/obx[results/reportable = 'true' and results/toHIS = 'true' and history='false' and matches(obxType, 'Result|Interpretation|PromptTest')
																   and observationMethod != 'DEFAULT']/observationId">
									<xsl:value-of select="."/>
				</xsl:for-each>
			</xsl:when>
			<xsl:when test="matches($callInfoExcludeCriteria, 'cancelled') and matches($callInfoExcludeCriteria, 'autodefault')
									and ($isCancelledTestComponents or $isAutoDefaultTestComponents)">
				<xsl:for-each select="$mess//obrLevel/obxLevel/obx[results/reportable = 'true' and results/toHIS = 'true' and history='false' and matches(obxType, 'Result|Interpretation|PromptTest')
																   and (($isCancelledTestComponents and (not($isAutoDefaultTestComponents)) and not(matches(observationResultStatus, 'Cancelled')))
																   or ($isCancelledTestComponents and ($isAutoDefaultTestComponents) 
																   and not(matches(observationResultStatus, 'Cancelled')) and observationMethod != 'DEFAULT')
															       or (not($isCancelledTestComponents) and (isAutoDefaultTestComponents) and observationMethod != 'DEFAULT'))]/observationId">
									<xsl:value-of select="."/>
				</xsl:for-each>
			</xsl:when>		
			<xsl:otherwise>
				<xsl:for-each select="$mess//obrLevel/obxLevel/obx[results/reportable = 'true' and results/toHIS = 'true' and history='false' and matches(obxType, 'Result|Interpretation|PromptTest')]/observationId">
					<xsl:value-of select="."/>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>    
    <!--
		The following variables determine the type of "identical" Called obx-es (main - send only one Called segment under OBR, other - send more than one Called segment under OBR).
		This is necessary to scenarios where OBR and OBX have the same Observation Code, where several current Called obx-es have the same Codes etc
	-->
    <xsl:variable name="calledTests" as="item()*">
		<xsl:for-each-group select="$messCall" group-by="concat(verificationDateTime, '-', observationValue)">
			<xsl:value-of select="." />
		</xsl:for-each-group>
	</xsl:variable>
	<xsl:variable name="notHistoricallCalledTests" as="item()*">
		<xsl:for-each-group select="$messNotHistoricalCall" group-by="concat(verificationDateTime, '-', observationValue)">
			<xsl:value-of select="." />
		</xsl:for-each-group>
	</xsl:variable>
	<xsl:variable name="countNotHistoricallCalledTests">
		<xsl:value-of select="count($notHistoricallCalledTests)"/>
	</xsl:variable>
    <xsl:variable name="typeCalledTests">
		<xsl:choose>
			<xsl:when test="count($notHistoricallCalledTests)=1">main</xsl:when>
			<xsl:otherwise>other</xsl:otherwise>
		</xsl:choose>
    </xsl:variable>
    <!--
		'calls' variable is the main variable which result is a structure:
		<call>
			<history/>																//patch: obxLevel/obx/history
			<valueForCall/>															//patch: obxLevel/obx/observationDescription or obxLevel/obx/observationValue, 'valueForCalls' parameter is responsible for this value
			<valueForCallHistorical/>												//patch: obxLevel/obx/observationDescription or obxLevel/obx/observationValue (where history=true), 'valueForCalls' parameter is responsible for this value
			<observationDescription/>												//patch: obxLevel/obx/observationDescription
			<observationDescriptionHistorical/>										//patch: obxLevel/obx/observationDescription (where history=true)
			<observationValue/>														//patch: obxLevel/obx/observationValue
			<observationValueHistorical/>											//patch: obxLevel/obx/observationValue (where history=true)
			<verificationDateTime/>													//patch: obxLevel/obx/verificationDateTime
			<verificationDateTimeHistorical/>										//patch: obxLevel/obx/verificationDateTime (where history=true)
			<doctor/>																//patch: obxLevel/obx/supplementalValues/@recipientName/value
			<verifiedBy><employeeId/></verifiedBy>									//patch: obxLevel/obx/verifiedBy/employeeId
			<verifiedByHistorical><employeeId/></verifiedByHistorical>				//patch: obxLevel/obx/verifiedBy/employeeId (where history=true)
			<reviewedBy><employeeId/></reviewedBy>									//patch: obxLevel/obx/reviewedBy/employeeId (where history=true)
			<reviewedDateTime/>														//patch: obxLevel/obx/reviewedDateTime (where history=true)
			<reviewedDate/>															//patch: obxLevel/obx/reviewedDateTime - only Date (where history=true)
			<reviewedTime/>															//patch: obxLevel/obx/reviewedDateTime - only Time (where history=true)
			<supplementalValues>
				<value n="callTo"></value>											//patch: obxLevel/obx/supplementalValues/@callTo/value
				<value n="phoneExtension"></value>									//patch: obxLevel/obx/supplementalValues/@phoneExtension/value
				<value n="phoneNumber"></value>										//patch: obxLevel/obx/supplementalValues/@phoneNumber/value
				<value n="recipientCode"></value>									//patch: obxLevel/obx/supplementalValues/@recipientCode/value
				<value n="recipientName"></value>									//patch: obxLevel/obx/supplementalValues/@recipientName/value
			</supplementalValues>
			<supplementalValuesHistorical>
				<value n="callTo"></value>											//patch: obxLevel/obx/supplementalValues/@callTo/value (where history=true)
				<value n="phoneExtension"></value>									//patch: obxLevel/obx/supplementalValues/@phoneExtension/value (where history=true)
				<value n="phoneNumber"></value>										//patch: obxLevel/obx/supplementalValues/@phoneNumber/value (where history=true)
				<value n="recipientCode"></value>									//patch: obxLevel/obx/supplementalValues/@recipientCode/value (where history=true)
				<value n="recipientName"></value>									//patch: obxLevel/obx/supplementalValues/@recipientName/value (where history=true)
			</supplementalValuesHistorical>
			<tests>
				<test/>
			</tests>
		</call>
	-->
	<xsl:variable name="calls">
		<!--
			Grouping current and historical Called obx-es with the same Observation Code, Call To and Verification Date/Time.
			This grouping is necessary because we need to handle scenarios where:
			- user called a few different tests at the same time (observationCode)
			- user called a few different tests at different times (observationCode + verificationDateTime)
			- user called the same test several times at different times (observationCode + verificationDateTime)
			- user called the same test at the same time but for different recipients (observationCode + verificationDateTime + callTo)
			- user called a few different tests at the same time for different recipients (observationCode + verificationDateTime + callTo)
			- and other
		-->
		<xsl:for-each-group select="$messCall" group-by="concat(observationCode, '-', supplementalValues/value[@n='callTo'], '-', verificationDateTime)">
			<!--
				Sorting grouped Called obx-es.
			-->
            <xsl:sort select="verificationDateTime" order="descending"/>
			<!--
				'history' variable contains history value
			-->
            <xsl:variable name="history" select="(current-group()[history='true']/history)[1]"/>
            <!--
				"Called By" placeholder in Tags Setup.
			-->
            <xsl:variable name="verifiedByHistorical" select="(current-group()[history='true']/verifiedBy/employeeId)[1]"/>
            <!--
				"Called Date" and "Called Time" placeholders in Tags Setup.
			-->
			<xsl:variable name="verificationDateTimeHistorical" select="(current-group()[history='true']/verificationDateTime)[1]"/>
			<!--
				"Old Message" placeholder in Tags Setup.
			-->
			<xsl:variable name="observationDescriptionHistorical" as="xs:string">
				<xsl:choose>
					<xsl:when test="$history='true'">
						<xsl:apply-templates select="(current-group()[history='true']/observationDescription)[1]" mode="callRTF"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="''"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="observationValueHistorical" as="xs:string">
				<xsl:choose>
					<xsl:when test="$history='true'">
						<xsl:apply-templates select="(current-group()[history='true']/observationValue)[1]" mode="secondCallRTF"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="''"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="valueForCallHistorical">
				<xsl:choose>
					<xsl:when test="$valueForCalls='reason'">
						<xsl:value-of select="$observationDescriptionHistorical"/>
					</xsl:when>
					<xsl:when test="$valueForCalls='message'">
						<xsl:value-of select="$observationValueHistorical"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$observationDescriptionHistorical"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<!--
				"Ward/Doctor Name" placeholder in Tags Setup.
			-->
			<xsl:variable name="recipientNameHistorical" select="(current-group()[history='true']/supplementalValues/value[@n = 'recipientName'])[1]"/>
			<xsl:variable name="upinHistorical" select="(current-group()[history='true']/supplementalValues/value[@n = 'upin'])[1]"/>
			<xsl:variable name="npiHistorical" select="(current-group()[history='true']/supplementalValues/value[@n = 'npi'])[1]"/>
			<!--
				"Telephone" placeholder in Tags Setup.
			-->
			<xsl:variable name="phoneNumberHistorical" select="(current-group()[history='true']/supplementalValues/value[@n = 'phoneNumber'])[1]"/>
			<!--
				"Ward/Doctor" placeholder in Tags Setup.
			-->
			<xsl:variable name="recipientCodeHistorical" select="(current-group()[history='true']/supplementalValues/value[@n = 'recipientCode'])[1]"/>
			<!--
				Other historical variables.
			-->
			<xsl:variable name="callToHistorical" select="(current-group()[history='true']/supplementalValues/value[@n = 'callTo'])[1]"/>
			<xsl:variable name="phoneExtensionHistorical" select="(current-group()[history='true']/supplementalValues/value[@n = 'phoneExtension'])[1]"/>
			<xsl:variable name="receivedDateTime" select="(current-group()[history='true']/receivedDateTime)[1]"/>
			<xsl:if test="current-group()/history='false'">			
				<call>
					<!--
						Variables for not historical Called obx-es.
					-->
					<!--
						"Date" and "Time" placeholder in Tags Setup.
					-->
					<xsl:variable name="verificationDateTime" select="(current-group()/verificationDateTime)[1]" /> 
					<!--
						"Changed on Date" and "Changed at Time" placeholders in Tags Setup.
					-->
					<xsl:variable name="reviewedDateTime" select="(current-group()/reviewedDateTime)[1]" /> 
					<!--
						"Description" placeholder in Tags Setup.
					-->
					<xsl:variable name="observationDescription" as="xs:string">
						<xsl:apply-templates select="(current-group()/observationDescription)[1]" mode="callRTF"/>
					</xsl:variable>
					<xsl:variable name="observationValue" as="xs:string">
						<xsl:apply-templates select="(current-group()/observationValue)[1]" mode="secondCallRTF"/>
					</xsl:variable>
					<xsl:variable name="valueForCall">
						<xsl:choose>
							<xsl:when test="$valueForCalls='reason'">
								<xsl:value-of select="$observationDescription"/>
							</xsl:when>
							<xsl:when test="$valueForCalls='message'">
								<xsl:value-of select="$observationValue"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$observationDescription"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!--
						"Ward/Doctor" placeholder in Tags Setup.
					-->
					<xsl:variable name="doctor" as="element()*" select="supplementalValues/value[@n = 'recipientName']"/>
					<history><xsl:value-of select="$history"/></history>
					<valueForCall><xsl:value-of select="$valueForCall"/></valueForCall>
					<valueForCallHistorical><xsl:value-of select="$valueForCallHistorical"/></valueForCallHistorical>
					<observationDescription><xsl:value-of select="$observationDescription" /></observationDescription>
					<observationDescriptionHistorical><xsl:value-of select="$observationDescriptionHistorical" /></observationDescriptionHistorical>
					<observationValue><xsl:value-of select="$observationValue" /></observationValue>
					<observationValueHistorical><xsl:value-of select="$observationValueHistorical" /></observationValueHistorical>
					<verificationDateTime><xsl:value-of select="$verificationDateTime" /></verificationDateTime>
					<verificationDateTimeHistorical><xsl:value-of select="$verificationDateTimeHistorical" /></verificationDateTimeHistorical>
					<doctor><xsl:value-of select="$doctor" /></doctor>
					<verifiedBy><employeeId><xsl:value-of select="(current-group()/verifiedBy/employeeId)[1]" /></employeeId></verifiedBy>
					<verifiedByHistorical><employeeId><xsl:value-of select="$verifiedByHistorical" /></employeeId></verifiedByHistorical>
					<reviewedBy><employeeId><xsl:value-of select="(current-group()/reviewedBy/employeeId)[1]" /></employeeId></reviewedBy>
					<reviewedDateTime><xsl:value-of select="$reviewedDateTime" /></reviewedDateTime>
					<reviewedDate><xsl:value-of select="cmn:format-dateTime($reviewedDateTime, '[M,2]/[D,2]/[Y]')" /></reviewedDate>
					<reviewedTime><xsl:value-of select="cmn:format-dateTime($reviewedDateTime, '[H,2]:[m,2]')" /></reviewedTime>
					<receivedDateTime><xsl:value-of select="$receivedDateTime" /></receivedDateTime>
					<supplementalValues>
						<value n="callTo">
							<xsl:value-of select="supplementalValues/value[@n = 'callTo']" />
						</value>
						<value n="phoneExtension">
							<xsl:value-of select="supplementalValues/value[@n = 'phoneExtension']" />
						</value>
						<value n="phoneNumber">
							<xsl:value-of select="supplementalValues/value[@n = 'phoneNumber']" />
						</value>
						<value n="recipientCode">
							<xsl:value-of select="supplementalValues/value[@n = 'recipientCode']" />
						</value>
						<value n="recipientName">
							<xsl:value-of select="supplementalValues/value[@n = 'recipientName']" />
						</value>
						<value n="upin">
							<xsl:value-of select="supplementalValues/value[@n = 'upin']"/>
						</value>
						<value n="npi">
							<xsl:value-of select="supplementalValues/value[@n = 'npi']"/>
						</value>
					</supplementalValues>
					<supplementalValuesHistorical>
						<value n="callTo">
							<xsl:value-of select="$callToHistorical" />
						</value>
						<value n="phoneExtension">
							<xsl:value-of select="$phoneExtensionHistorical" />
						</value>
						<value n="phoneNumber">
							<xsl:value-of select="$phoneNumberHistorical" />
						</value>
						<value n="recipientCode">
							<xsl:value-of select="$recipientCodeHistorical" />
						</value>
						<value n="recipientName">
							<xsl:value-of select="$recipientNameHistorical" />
						</value>
						<value n="upin">
							<xsl:value-of select="$upinHistorical"/>
						</value>
						<value n="npi">
							<xsl:value-of select="$npiHistorical"/>
						</value>
					</supplementalValuesHistorical>
					<xsl:variable name="tests" as="item()*">
						<xsl:for-each select="$mess//obrLevel/obxLevel/obx[obxType='CallInfo' and verificationDateTime = $verificationDateTime and (history='false' or not(history))]/observationId"> 
							<xsl:value-of select="." />
						</xsl:for-each>
					</xsl:variable>
					<xsl:variable name="obrTestCall" as="item()*">
						<xsl:for-each select="$mess//obrLevel/obxLevel/obx[obxType='CallInfo' and verificationDateTime = $verificationDateTime and (history='false' or not(history)) and observationId=../../obr/testId and observationCode=../../obr/testId]/observationId"> 
							<xsl:value-of select="." />
						</xsl:for-each>
					</xsl:variable>
					<xsl:variable name="otherTests" as="item()*">
						<xsl:for-each select="$allTests">
							<xsl:if test="not(index-of($tests, .) > 0)">
								<xsl:value-of select="." />
							</xsl:if>
						</xsl:for-each>
					</xsl:variable>
					<!--
						The following section 'tests' determines the location of CALLED and M_CALLED NTE comments.
						'test' element contains code test (Observation Id) under which CALLED or M_CALLED NTE comments will be created.
						Sample scenarios:
						- The user created order with one single and called test. Result: one CALLED NTE should be placed under OBR and one under OBX.
						- The user created order with one group test (with two single and called tests). Result: one CALLED NTE should be placed under OBR.
						- The user created order with one group test (with two single tests where only one is called). Result: one CALLED NTE should be placed under OBR (for called test) and one under OBX (for called test).
						- The user created order with one single and called test and then user modified the message for previously Called test. Result: one M_CALLED NTE should be placed under OBR and one under OBX.
						- The user created order with one group test (with two single and called tests) and then user modified the message for previously single Called tests. Result: one M_CALLED NTE should be placed under OBR.
						- The user created order with one group test (with two single tests where only one is called) and then user modified the message for one previously single Called test. Result: one M_CALLED NTE should be placed under OBR (for modified called test) and one under OBX (for modified called test).
						where:
						- sendHistoricalCallInfo=true
					-->
					<tests> 
						<xsl:choose>
							<xsl:when test="$enableExtendedCalledMode = 'true'">
								<xsl:for-each select="current-group()">
									<test>
									<xsl:attribute name="obrTestCall" select="count($obrTestCall)"/>
										<xsl:value-of select="observationId" />
									</test>
								</xsl:for-each>
							</xsl:when>
							<xsl:when test="(count($tests) = 1 and matches($callInfoExcludeCriteria, '-|none')) or $countTestComponents != (count($tests) + sum(for $t in $otherTests return if (exists($mess//obrLevel/obxLevel/obx[observationId = $t and obxType='CallInfo' and observationResultReason = 'PANIC'])) then 1 else 0 ))">
								<xsl:for-each select="current-group()">
									<test>
										<xsl:attribute name="observationCode" select="observationCode"/>
										<xsl:value-of select="observationId" />
									</test>
								</xsl:for-each>
							</xsl:when>
							<xsl:otherwise>
								<test>
									<xsl:value-of select="$mess//obrLevel/obr/testId" />
								</test>
							</xsl:otherwise>
						</xsl:choose>
					</tests>
				</call>
			</xsl:if>
        </xsl:for-each-group>
    </xsl:variable>
    <xsl:variable name="tz" select="format-dateTime(current-dateTime(),'[Z0001]')"/>
    <xsl:template match="call/observationValue" mode="callRTF">
		<xsl:variable name="plainText" select="rtf:rtf2str(., $rtfSymbolsTable, $txtSymbolsTable)"/>
		<!--<xsl:variable name="plainText" select="."/>-->
		<xsl:variable name="choppedPlainText">
			<xsl:call-template name="removeFrontEndCarriageReturns">
				<xsl:with-param name="inputString" select="$plainText"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:value-of select="$choppedPlainText"/>
	</xsl:template>
    <xsl:template match="observationValue" mode="secondCallRTF">
		<xsl:variable name="plainText" select="rtf:rtf2str(., $rtfSymbolsTable, $txtSymbolsTable)"/>
		<!--<xsl:variable name="plainText" select="."/>-->
		<xsl:variable name="choppedPlainText">
			<xsl:call-template name="removeFrontEndCarriageReturns">
				<xsl:with-param name="inputString" select="$plainText"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:value-of select="$choppedPlainText"/>
	</xsl:template>
	<xsl:template match="observationDescription" mode="callRTF">
		<xsl:variable name="plainText" select="rtf:rtf2str(., $rtfSymbolsTable, $txtSymbolsTable)"/>
		<!--<xsl:variable name="plainText" select="."/>-->
		<xsl:variable name="choppedPlainText">
			<xsl:call-template name="removeFrontEndCarriageReturns">
				<xsl:with-param name="inputString" select="$plainText"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:value-of select="$choppedPlainText"/>
	</xsl:template>
	<!--
		Required in removeFrontEndCarriageReturns.
	-->
	<xsl:template name="findLast">
		<xsl:param name="str"/>
		<xsl:variable name="after" select="substring-after($str, $delim)"/>
		<xsl:choose>
			<xsl:when test="string-length($after) &gt; 0">
				<xsl:call-template name="findLast">
					<xsl:with-param name="str" select="$after"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="substring-before($str, $delim)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!--
		Required in removeFrontEndCarriageReturns.
	-->
	<xsl:template name="lastElement">
		<xsl:param name="input"/>
		<xsl:param name="lastTxt"/>
		<xsl:variable name="aft1" select="substring-after($input, $lastTxt)"/>
		<xsl:variable name="conFirst">
			<xsl:value-of select="substring-before($input, $lastTxt)"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="string-length($aft1) &gt; 0">
				<xsl:variable name="pos" select="string-length($conFirst) + string-length($lastTxt) + 1"/>
				<xsl:variable name="firstpart" select="substring($input, 0, $pos)"/>
				<xsl:variable name="secondpart" select="substring($input, $pos)"/>
				<xsl:variable name="lastEl">
					<xsl:call-template name="lastElement">
						<xsl:with-param name="input" select="$secondpart"/>
						<xsl:with-param name="lastTxt" select="$lastTxt"/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:value-of select="concat($firstpart, $lastEl)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="substring-before($input, $lastTxt)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!--
		Removes empty leading and trailing lines from the string.
	-->
	<xsl:template name="removeFrontEndCarriageReturns">
		<xsl:param name="inputString"/>
		<xsl:variable name="uxent" select="'&#xA;'"/>
		<xsl:variable name="inpString">
			<xsl:value-of select="$inputString"/>
		</xsl:variable>
		<xsl:variable name="con">
			<xsl:for-each select="tokenize($inpString, $uxent)">
				<xsl:if test="string-length(normalize-space(.)) &gt; 0">
					<xsl:value-of select="concat(., $delim)"/>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="isEnter">
			<xsl:for-each select="tokenize($inpString, $uxent)">
				<xsl:if test="position() = last() and string-length(.) &gt; 0">N</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="conFirst">
			<xsl:value-of select="substring-before($con, $delim)"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="string-length(substring-after($con, $delim)) = 0">
				<xsl:value-of select="replace(replace($inpString,'\r',' '), '\n', '')"/>
			</xsl:when>
			<xsl:when test="$isEnter = 'N'">
				<xsl:value-of select="concat($conFirst, substring-after($inpString, $conFirst))"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="conLast">
					<xsl:call-template name="findLast">
						<xsl:with-param name="str" select="$con"/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:variable name="cutEnd">
					<xsl:call-template name="lastElement">
						<xsl:with-param name="input" select="$inpString"/>
						<xsl:with-param name="lastTxt" select="$conLast"/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:value-of select="concat($conFirst, substring-after($cutEnd, $conFirst))"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!--
		Create ELSG comment.
	-->
	<xsl:template name="reviewedSignatureELSG">
		<xsl:element name="nteLevel">
			<xsl:element name="nte">
				<xsl:element name="id">ELSG</xsl:element>
				<xsl:element name="comment">
					<xsl:choose>
						<xsl:when test="technology = 'LAB'">
							<xsl:value-of select="reviewedSignature"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="concat($textForELSG, ' ', reviewedSignature, ', Signed on ','%DDDDDDDD%',' at ','%TTT%')"/>
						</xsl:otherwise>
					</xsl:choose>	
				</xsl:element>
				<xsl:element name="dateTime">
					<xsl:value-of select="cmn:format-dateTime(reviewedDateTime, '[Y][M,2][D,2][H,2][m,2]')"/>
				</xsl:element>
			</xsl:element>
		</xsl:element>
	</xsl:template>
	<!--
		Tags Format main template
	-->
	<xsl:template name="tagsFormat">
		<xsl:param name="tag"/>
		<xsl:param name="readTagLayout"/>
		<xsl:param name="built-in"/>
		<xsl:param name="date"/>
		<xsl:param name="date2"/>
		<xsl:param name="map" select="'false'"/>
		<xsl:variable name="map">
			<xsl:choose>
				<xsl:when test="$map='false'"><xsl:call-template name="markersMapping"/></xsl:when>
				<xsl:otherwise><xsl:copy-of select="$map"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:call-template name="createComment">
			<xsl:with-param name="commType" select="$tag"/>
			<xsl:with-param name="commFormat">
				<xsl:choose>
					<xsl:when test="cmn:matchPatern($tag,$readTagsFormat, ',') and $mess/TagsFormat/rows/row[TAGCODE=$tag and TSACTIVE = 'Y'][1]/TSTAGTEXT/text()">
						<xsl:value-of select="$mess/TagsFormat/rows/row[TAGCODE=$tag and TSACTIVE = 'Y'][1]/TSTAGTEXT"/>
					</xsl:when>
					<xsl:when test="not(cmn:matchPatern($tag,$readTagsFormat, ',')) and string($readTagLayout) and contains($readTagLayout,'%') and not(cmn:matchPatern('-',$readTagLayout, ','))">
						<xsl:value-of select="$readTagLayout"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$built-in"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:with-param>
			<xsl:with-param name="commMap" select="$map"/>
			<xsl:with-param name="date" select="$date"/>
			<xsl:with-param name="date2" select="$date2"/>
		</xsl:call-template>
	</xsl:template>
	<!--
		createCancellationComment.
	-->
	<xsl:template name="createCancellationComment">
		<xsl:variable name="map">
			<comment id='TCANC'>
				<!--%1 was cancelled on %2 at %3 by %4; %5
					%1 	Test Name
					%2	Date
					%3	Time
					%4	By
					%5   ?Reason-->
				<code>
					<from>%5</from>
					<to eval="n"><xsl:apply-templates select="obr/cancellationReason"/></to>
				</code>
				<code>
					<from>%4</from>
					<to eval="y">obr/cancellationBy</to>
				</code>
				<code>
					<from>%3</from>
					<to eval="n">%TTT%</to>
				</code>
				<code>
					<from>%2</from>
					<to eval="n">%DDDDDDDD%</to>
				</code>
				<code>
					<from>%1</from>
					<to eval="y">obr/testName</to>
				</code>
			</comment>
		</xsl:variable>
		<xsl:variable name="commentContent" as="xs:string">
			<xsl:choose>
				<xsl:when test="obr/cancellationReason/text()">
					<xsl:apply-templates select="obr/cancellationReason"/>
				</xsl:when>
				<xsl:otherwise><xsl:value-of select="''"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="builtInCommentTCANC">
			<xsl:value-of select="concat(obr/testName, ' was cancelled on %DDDDDDDD% at %TTT%; ', $commentContent)"/>
		</xsl:variable>
		<xsl:call-template name="tagsFormat">
			<xsl:with-param name="tag" select="'TCANC'"/>
			<xsl:with-param name="readTagLayout" select="$readTagLayoutTCANC"/>
			<xsl:with-param name="built-in" select="$builtInCommentTCANC"/>
			<xsl:with-param name="map" select="$map"/>
			<xsl:with-param name="date" select="obr/cancellationDate"/>
		</xsl:call-template>
	</xsl:template>
	<!--
		****************************************************************************
		*** <xsl:template match...
		****************************************************************************
	-->
	<xsl:template match="call">
		<xsl:variable name="builtInCommentCALLED">
			<xsl:value-of select="concat('Called to ', doctor, ', ', '%DDDDDDDD% %TTT%', ', by ', verifiedBy/employeeId)"/>
		</xsl:variable>
		<xsl:variable name="builtInCommentM_CALLED">
			<xsl:value-of select="concat('Called message corrected to ', valueForCall, ' by ', reviewedBy/employeeId, ' on %DDDDDDDD% at %TTT%, previously called as ', valueForCallHistorical, ' by ', verifiedByHistorical/employeeId, ' on %DDDDDDD2% at %TT2%')"/>
		</xsl:variable>
		<xsl:choose>
		<!--Support historical and current Called obx-es.-->	
			<xsl:when test="$sendHistoricalCallInfo='true'">
				<xsl:choose>
					<xsl:when test="history='true'">
						<xsl:call-template name="tagsFormat">
							<xsl:with-param name="tag" select="'M_CALLED'"/>
							<xsl:with-param name="readTagLayout" select="$readTagLayoutM_CALLED"/>
							<xsl:with-param name="built-in" select="$builtInCommentM_CALLED"/>
							<xsl:with-param name="date" select="reviewedDateTime"/>
							<xsl:with-param name="date2" select="receivedDateTime"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:when test="history='false' or not(string(history))">
						<xsl:call-template name="tagsFormat">
							<xsl:with-param name="tag" select="'CALLED'"/>
							<xsl:with-param name="readTagLayout" select="$readTagLayoutCALLED"/>
							<xsl:with-param name="built-in" select="$builtInCommentCALLED"/>
							<xsl:with-param name="date" select="verificationDateTime"/>
						</xsl:call-template>
					</xsl:when>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="tagsFormat">
					<xsl:with-param name="tag" select="'CALLED'"/>
					<xsl:with-param name="readTagLayout" select="$readTagLayoutCALLED"/>
					<xsl:with-param name="built-in" select="$builtInCommentCALLED"/>
					<xsl:with-param name="date" select="verificationDateTime"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!--  shell - shadow logic -->
	<!-- shellShadowMessage transaction - contains @reflexType='S' -->
	<xsl:variable name="shellShadowMessage" as="xs:boolean">
		<xsl:choose>
			<xsl:when test="//obxLevel/obx[@reflexType='S']">
				<xsl:value-of select="true()"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="false()"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<!-- check if any dspLevel contains @reportId -->
	<xsl:variable name="dspReportId" as="xs:boolean">
		<xsl:choose>
			<xsl:when test="//dspLevel[@reportId]">
				<xsl:value-of select="true()"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="false()"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<!-- remove all dsp if dspReportId='true'  -->
	<xsl:template match="dspLevel[$dspReportId]"/>
	<!-- shell obx -->
	<xsl:variable name="shellObx" select="//obx[ valueType='RP'  and not(@reflexType='S') and history='false' and observationCode=//Event/msg/attributes[name='TEST']/value]"/>
	<xsl:template match="obrLevel">
		<xsl:variable name="currentTestId" select="obr/testId"/>
		<xsl:element name="obrLevel">
			<xsl:apply-templates/>
			<!-- recreate dsp segments acording to the new structure -->
			<xsl:for-each-group select="dspLevel[$dspReportId]" group-by="string(@reportId)">
				<!-- shadowTestName -->
				<xsl:variable name="testName">
					<xsl:choose>
						<xsl:when test="//obxLevel/obx[history='false' and valueType='RP' and reportId=current-grouping-key()]/observationDescription">
							<xsl:value-of select="//obxLevel/obx[history='false' and valueType='RP' and reportId=current-grouping-key()]/observationDescription"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="//obxLevel/obx[history='false' and section='TestHeader' and reportId=current-grouping-key()]/observationDescription"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<!-- shadowTestCode -->
				<xsl:variable name="testCode">
					<xsl:choose>
						<xsl:when test="//obxLevel/obx[history='false' and valueType='RP' and reportId=current-grouping-key()]/observationCode">
							<xsl:value-of select="//obxLevel/obx[history='false' and valueType='RP' and reportId=current-grouping-key()]/observationCode"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="//obxLevel/obx[history='false' and section='TestHeader' and reportId=current-grouping-key()]/observationCode"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<!-- Coppy the dsp segments for:
						- all non shel-shadow messages 
						- shell obx if the shell obx report has reportable='true' ( Transmit PDF Report link to HIS )
						- all reportable shadows ( Reportable to external system ) if the shell obx is not reportable    -->
				<xsl:if test="not($shellShadowMessage) or 
									( $shellShadowMessage and  $shellObx/results/reportable='true' and current-grouping-key()=$shellObx/reportId )
										or ( $shellShadowMessage and not( $shellObx/results/reportable='true' ) and (//obx[ obxType='TestInfo' and @reflexType='S' and  reportId=current-grouping-key() and results/reportable='true' ]) )">
					<xsl:element name="dspLevel">
						<xsl:copy-of select="@*"/>
							<xsl:element name="dsp">
								<!-- Start delimeter -->
								<xsl:if test="$startShadowReportDelimiter!='-' and $shellShadowMessage">			
									<xsl:element name="comment">
										<xsl:value-of select="replace(replace($startShadowReportDelimiter,'%1',$testCode),'%2',$testName) "/>
									</xsl:element>
								</xsl:if>
								<!-- Coppy the dsp from canonnical -->
								<xsl:apply-templates select="//dspLevel[string(@reportId)=current-grouping-key()]/dsp/node()"/>
								<!-- End delimeter -->
								<xsl:if test="$endShadowReportDelimiter!='-' and $shellShadowMessage">
									<xsl:element name="comment">
										<xsl:value-of select="replace(replace($endShadowReportDelimiter,'%1',$testCode),'%2',$testName) "/>
								</xsl:element>
							</xsl:if>
						</xsl:element>
					</xsl:element>
				</xsl:if>
			</xsl:for-each-group>
			<!--createCancellationComment-->
			<!-- comments for absorption and duplication from HIS will be created in 05xslToHL7ForLab.xsl -->
			<!-- BB is excluded cause TCANC tag will be created directly from NTE|TCANC provided by BB in bbCan2MU2.xslt -->
			<xsl:if test="obr/cancellationDate/text() and obr/cancellationBy and $event != 'TEST_REJECTED' and not(obr/cancellationReason/text() and obr/redundant = 'true') and not(/Message/Event/msg/senderCode='BB')">
				<xsl:call-template name="createCancellationComment"/>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="$typeCalledTests='main'">
					<xsl:apply-templates select="$calls/call[1]"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="$calls/call"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:element>
	</xsl:template>
	<xsl:template match="obx[
							obxType = 'TestInfo'
							and history = 'false'
							and section = 'TestHeader'
						]">
		<xsl:variable name="currentObservationId" select="observationId"/>
		<xsl:variable name="currentObservationCode" select="observationCode"/>
		<xsl:variable name="currentTestId" select="//obrLevel/obr/testId"/>
		<obx>
			<!-- Copy all attributes -->
			<xsl:apply-templates select="@*"/>
			<!-- Copy current OBX segment. -->
			<xsl:choose>
				<xsl:when test="not(string(observationSecId))">
					<xsl:apply-templates select="*[local-name() != 'observationSecId']"/>
					<observationSecId>
						<xsl:value-of select="observationId"/>
					</observationSecId>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="*"/>
				</xsl:otherwise>
			</xsl:choose>
		</obx>
		<!-- add RMOD generated from Component-->
		<xsl:if test="technology='IWS' and count(//obxLevel/obx[obxType='Component' and history='true' and observationId=$currentObservationId]) &gt; 0">
			<xsl:for-each select="//obxLevel/obx[obxType='Component' and history='true' and observationId=$currentObservationId]">
				<xsl:sort select="verificationDateTime" />
				<xsl:if test="position()=1" >
					<xsl:element name="nteLevel">
								<xsl:element name="nte">
									<xsl:element name="id">RMOD</xsl:element>
									<xsl:variable name="obsValueHistory" select="observationValue" />
									<xsl:variable name="dateTimeHistory" select="observationDateTime" />
									<xsl:variable name="formattedComment" as="xs:string">
												<xsl:value-of select="concat('Corrected result; Previously reported as: ',
																	$obsValueHistory,
																	' on ',
																	'%DDDDDDDD% at %TTT%')"/>
									</xsl:variable>
									<xsl:element name="comment"><xsl:value-of select="$formattedComment" /></xsl:element>
									<xsl:element name="dateTime">
										<xsl:value-of select="cmn:format-dateTime($dateTimeHistory, '[Y][M,2][D,2][H,2][m,2]')"/>
									</xsl:element>
								</xsl:element>
					</xsl:element>
				</xsl:if>
			</xsl:for-each>
		</xsl:if>
		<xsl:if test="(technology='LAB' and reviewedDocumentation = 'true' and string(reviewedSignature)) or (technology!='LAB' and string(reviewedSignature))">
				<xsl:call-template name="reviewedSignatureELSG"/>
		</xsl:if>
		<xsl:choose>
			<xsl:when test="$calls/call[tests/test = $currentObservationId][$enableExtendedCalledMode='false']">
				<xsl:apply-templates select="$calls/call[tests/test = $currentObservationId][$enableExtendedCalledMode='false']" />
			</xsl:when>
			<xsl:when test="$calls/call[tests/test/@observationCode = $currentObservationId][$enableExtendedCalledMode='false']">
				<xsl:apply-templates select="$calls/call[tests/test/@observationCode = $currentObservationId][$enableExtendedCalledMode='false']" />
			</xsl:when>
			<xsl:otherwise/>
		</xsl:choose>
	</xsl:template>
	<!--
		Comments formatting (TCANC) from cmn_tagMapping.xslt
	-->
	<xsl:template match="nteLevel[
									nte/id = 'TCANC'
									and string(normalize-space(nte/comment))
									and not(nte/systemCode='BB')
								  ]">
		<!-- Apply RTF conversion -->
		<xsl:variable name="commentContent" as="xs:string">
			<xsl:apply-templates select="nte/comment"/>
		</xsl:variable>
		<xsl:variable name="builtInCommentTCANC">
			<xsl:value-of select="concat(../obx/observationDescription, ' was cancelled on %DDDDDDDD% at %TTT%; ', $commentContent)"/>
		</xsl:variable>
			<xsl:call-template name="tagsFormat">
				<xsl:with-param name="tag" select="'TCANC'"/>
				<xsl:with-param name="readTagLayout" select="$readTagLayoutTCANC"/>
				<xsl:with-param name="built-in" select="$builtInCommentTCANC"/>
				<xsl:with-param name="date" select="nte/enteredDateTime"/>
			</xsl:call-template>
	</xsl:template>
	<!--	
		Comments formatting MODCOM (historical PATCOM, STAYCOM, ORDCOM):
			- from SoftLab Setup/Reports/Tags setup.	
			- directly from readTagLayoutMODCOM parameter
			- or use built-in
	-->
	<xsl:template match="nteLevel[
									$sendModcomComment = 'true'
									and nte/history = 'true'
									and matches(nte/id, '(PATCOM|STAYCOM|ORDCOM)')
									and string(normalize-space(nte/comment))
								]">
								
		<xsl:variable name="currentCommentId" select="nte/id"/>
		<!-- Apply RTF conversion -->
		<xsl:variable name="commentContent" as="xs:string"><xsl:apply-templates select="nte/comment"/></xsl:variable>
		<xsl:variable name="builtInCommentMODCOM">
			<xsl:variable name="comment" select="tokenize($commentContent,'\n')"/>
			<xsl:variable name="toSend" select="count($comment[ substring(.,1,1) !='?' ])"/>
			<xsl:variable name="firstToSend" select="$comment[ substring(.,1,1) !='?' ][ position() = 1]"/>
			<xsl:for-each select="tokenize($commentContent,'\n')">
				<xsl:choose>
					<xsl:when test="$toSend &gt; 0 and string(.) = $firstToSend">
						<xsl:value-of select="concat('Previous comment was: ', . )"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="."/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:if test="position() != last()">
					<xsl:value-of select="string('&#10;')"/>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:call-template name="tagsFormat">
			<xsl:with-param name="tag" select="'MODCOM'"/>
			<xsl:with-param name="readTagLayout" select="$readTagLayoutMODCOM"/>
			<xsl:with-param name="built-in" select="$builtInCommentMODCOM"/>
			<xsl:with-param name="date" select="nte/enteredDateTime"/>
		</xsl:call-template>
	</xsl:template>
	<!--	
		Comments formatting MODCOT (historical FCOM): 
			- from SoftLab Setup/Reports/Tags setup.	
			- directly from readTagLayoutMODCOT parameter
			- or use built-in
	-->
	<xsl:template match="nteLevel[
									not($isMicroTransaction)
									and nte/history = 'true'
									and parent::obxLevel/obx/history[not(@modificationType = 'PathologistReview')]
									and nte/id = 'FCOM'
									and string(normalize-space(nte/comment))
								 ]">
				<xsl:variable name="commentContent" as="xs:string">
					<xsl:apply-templates select="nte/comment"/>
				</xsl:variable>
				<xsl:variable name="historicalVerificationDateTime">
					<xsl:value-of select="concat(../obx/verificationDateTime,$tz)"/>
				</xsl:variable>
				<xsl:variable name="builtInCommentMODCOT">
					<xsl:value-of select="concat('REVISED REPORT, Previously reported as: ',
											$commentContent,
											' (Reported ',
											$historicalVerificationDateTime,
											')')"/>
				</xsl:variable>
				<xsl:call-template name="tagsFormat">
					<xsl:with-param name="tag" select="'MODCOT'"/>
					<xsl:with-param name="readTagLayout" select="$readTagLayoutMODCOT"/>
					<xsl:with-param name="built-in" select="$builtInCommentMODCOT"/>
					<!--<xsl:with-param name="date" select="nte/enteredDateTime"/>-->
					<xsl:with-param name="date" select="../obx/verificationDateTime"/>
					<xsl:with-param name="date2" select="../preceding-sibling::obxLevel[1]/obx/observationDateTime"/>
				</xsl:call-template>
	</xsl:template>
	<!--	
		Comments formatting DMOD:
			- from SoftLab Setup/Reports/Tags setup.	
			- directly from readTagLayoutDMOD parameter
			- or use built-in
	-->
	<xsl:template match="obx[
								not($isMicroTransaction)
								and history[not(@modificationType = 'PathologistReview')] = 'true'
								and string(observationValue)
							
							]" mode="DMOD">
		<xsl:param name="currentVerificationDateTime"/>
		<xsl:variable name="historicalVerificationDateTime" select="verificationDateTime" />
		<!-- Apply RTF conversion -->
		<xsl:variable name="obsValueContent" as="xs:string"><xsl:apply-templates select="observationValue"/></xsl:variable>
		<xsl:variable name="observer" select="verifiedBy/employeeId"/>
		<xsl:variable name="builtInCommentDMOD">
			<xsl:value-of select="concat('Demographic adjusted - previously reported as: ',
										$obsValueContent, ' ',
										abnormalFlags, ', ',
										'verified by ',
										$observer, ' at %TT2% on %DDDDDDD2%')"/>
		</xsl:variable>
		<xsl:call-template name="tagsFormat">
			<xsl:with-param name="tag" select="'DMOD'"/>
			<xsl:with-param name="readTagLayout" select="$readTagLayoutDMOD"/>
			<xsl:with-param name="built-in" select="$builtInCommentDMOD"/>
			<xsl:with-param name="date" select="$currentVerificationDateTime"/>
			<xsl:with-param name="date2" select="$historicalVerificationDateTime"/>
		</xsl:call-template>
	</xsl:template>
	<!--	
		Comments formatting RMOD
			- from SoftLab Setup/Reports/Tags setup.	
			- directly from readTagLayoutRMOD parameter
			- or use built-in
	-->
	<xsl:template match="obx[
								not($isMicroTransaction)
								and history[not(@modificationType = 'PathologistReview')] = 'true'
								and string(observationValue)
								
							]" mode="RMOD">
		<xsl:param name="currentVerificationDateTime" />
		<xsl:variable name="historicalVerificationDateTime" select="concat(verificationDateTime,$tz)" />
		<!-- Apply RTF conversion -->
		<xsl:variable name="obsValueContent" as="xs:string">
			<xsl:apply-templates select="observationValue"/>
		</xsl:variable>
		<xsl:variable name="builtInCommentRMOD" as="xs:string">
			<xsl:choose>
				<xsl:when test="$includeChangeReasonRMOD != '-' and observationResultReason/text()">
					<xsl:choose>
						<xsl:when test="$includeChangeReasonRMOD = 'beforeTmSt'">
							<xsl:value-of select="concat('REVISED REPORT, Previously reported as: ',
										$obsValueContent,
										concat(' ', observationResultReason),
										' (Reported ',
										'%DDDDDDDD% %TTT%',
										')')"/>
						</xsl:when>
						<xsl:when test="$includeChangeReasonRMOD = 'afterTmSt'">
							<xsl:value-of select="concat('REVISED REPORT, Previously reported as: ',
										$obsValueContent,
										' (Reported ',
										'%DDDDDDDD% %TTT%',
										concat(' ', observationResultReason),
										')')"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="concat('REVISED REPORT, Previously reported as: ',
										$obsValueContent,
										' (Reported ',
										'%DDDDDDDD% %TTT%',
										')')"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat('REVISED REPORT, Previously reported as: ',
										$obsValueContent,
										' (Reported ',
										$historicalVerificationDateTime,
										')')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:call-template name="tagsFormat">
			<xsl:with-param name="tag" select="'RMOD'"/>
			<xsl:with-param name="readTagLayout" select="$readTagLayoutRMOD"/>
			<xsl:with-param name="built-in" select="$builtInCommentRMOD"/>
			<xsl:with-param name="date" select="$historicalVerificationDateTime"/>
			<xsl:with-param name="date2" select="$currentVerificationDateTime"/>
		</xsl:call-template>
		<!-- 
			Copy canned message comments (nte levels with "@..."). 
			Only to build RMOD comments (<xsl:template name="expandCannedMessages".. in "common.xslt")
			These comments will be removed in "common.xslt" (xsl:for-each select="../nteLevel[not(info='DROP')]/nte"...).
		-->
		<xsl:for-each select="../nteLevel[starts-with(nte/id, '@')]">
			<xsl:element name="nteLevel">
				<xsl:copy-of select="./nte"/>
				<xsl:element name="info">DROP</xsl:element>
			</xsl:element>
		</xsl:for-each>
	</xsl:template>
	<!--	
		Comments ids conversion (INTERP_MESSAGE).	
	-->
	<xsl:template match="nteLevel/nte[not($isMicroTransaction) and id = 'INTERP_MESSAGE']/id">
		<xsl:element name="id">
			<xsl:variable name="abnormalFlag">
				<xsl:value-of select="../../../obx/abnormalFlags"/>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$abnormalFlag = 'Panic_Low'">LPNV</xsl:when>
				<xsl:when test="$abnormalFlag = 'Panic_High'">HPNV</xsl:when>
				<xsl:when test="$abnormalFlag = 'Abnormal_Low'">LANV</xsl:when>
				<xsl:when test="$abnormalFlag = 'Abnormal_High'">HANV</xsl:when>
				<xsl:when test="$abnormalFlag = 'Absurd_Low'">LABV</xsl:when>
				<xsl:when test="$abnormalFlag = 'Absurd_High'">HABV</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:element>
	</xsl:template>
	<!--
		OBX for GENE interpretation
	-->
	<xsl:template match="obx[
							obxType = 'Interpretation'
							and history = 'false'
							and (
								not(section)
								or section != 'InterpretationPlaceholder' 
							)
						]">
		<obx>
			<!-- Copy all attributes -->
			<xsl:apply-templates select="@*"/>
			<!-- Copy current OBX segment. -->
			<xsl:apply-templates/>
		</obx>
		<!-- Get current observation code. -->
		<xsl:variable name="currentObservationCode" select="observationCode"/>
		<!-- Get current observation code. -->
		<xsl:variable name="currentAlternateObservationId" select="alternateObservationId[@type='SECTIONCODE']"/>
		<!-- Current OBX type. -->
		<xsl:variable name="currentOBXType" select="obxType"/>
		<!-- Current result value. -->
		<xsl:variable name="currentObservationValue" select="observationValue"/>
		
		<!-- verificationDateTime from newer OBX -->		
		<xsl:variable name="verificationDateTime2">
			<data>
				<xsl:for-each-group select="../../obxLevel/obx[
												obxType = $currentOBXType
												and alternateObservationId[@type='SECTIONCODE'] = $currentAlternateObservationId
												and observationCode = $currentObservationCode
											]" group-adjacent="observationValue">
											<xsl:sort select="verificationDateTime" order="descending"/>
											<xsl:variable name="currentObx" select="."/>									
											<node>
												<xsl:attribute name="id" select="generate-id($currentObx)"/>
												<verDT><xsl:value-of select="verificationDateTime"/></verDT>
											</node>									
				</xsl:for-each-group>
			</data>
		</xsl:variable>
		<xsl:for-each-group select="../../obxLevel/obx[
											history = 'true'
											and obxType = $currentOBXType
											and alternateObservationId[@type='SECTIONCODE'] = $currentAlternateObservationId
											and observationCode = $currentObservationCode
										]" group-adjacent="observationValue">
			<xsl:sort select="verificationDateTime" order="descending"/>
			<!-- Create RMOD. but only when real change occurred. -->
			<xsl:variable name="genIdObx" select="generate-id(.)"/>
			<xsl:choose>
				<xsl:when test="$sendAllRMODs='true'">
					<xsl:apply-templates select="current-group()[1][string(observationValue)]" mode="RMOD">
						<xsl:with-param name="currentVerificationDateTime" select="$verificationDateTime2/data/node[@id = $genIdObx]/preceding-sibling::*[1]/verDT"/>
					</xsl:apply-templates>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="current-group()[1][string(observationValue) and observationValue != $currentObservationValue]" mode="RMOD">
						<xsl:with-param name="currentVerificationDateTime" select="$verificationDateTime2/data/node[@id = $genIdObx]/preceding-sibling::*[1]/verDT"/>
					</xsl:apply-templates>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each-group>
		<xsl:if test="(technology='LAB' and reviewedDocumentation = 'true' and string(reviewedSignature)) or (technology!='LAB' and string(reviewedSignature))">
			<xsl:call-template name="reviewedSignatureELSG"/>
		</xsl:if>
	</xsl:template>
	<!--
		LAB results
	-->
	<xsl:template match="obx[
							not($isMicroTransaction)
							and history = 'false'
							and obxType = 'Result'
						]">
		<obx>
			<!-- Copy all attributes -->
			<xsl:apply-templates select="@*"/>
			<!-- Copy current OBX segment. -->
			<xsl:apply-templates/>
		</obx>
		<xsl:variable name="currentObservationCode" select="observationCode"/>
		<xsl:variable name="currentTestId" select="//obr/testId"/>
		<!-- Save current test id (it's for LAB part). -->
		<xsl:variable name="currentObservationId" select="observationId"/>
		<!-- Current OBX type. -->
		<xsl:variable name="currentOBXType" select="obxType"/>
		<!-- Current result value. -->
		<xsl:variable name="currentObservationValue" select="observationValue"/>
		<!-- Current referenceRange. -->
		<xsl:variable name="currentReferenceRange" select="referenceRange"/>
		<!-- Current observationSubId. -->
		<xsl:variable name="observationSubId" select="observationSubId"/>		
		<!-- verificationDateTime from newer OBX -->
		<xsl:variable name="verificationDateTime2">
			<data>
				<xsl:for-each-group select="../../obxLevel/obx[
												obxType = $currentOBXType
												and observationId = $currentObservationId
												and ((observationCode = $currentObservationCode) or not($currentObservationCode))
											]" group-adjacent="string(normalize-space(observationValue))">
											<xsl:sort select="verificationDateTime" order="descending"/>
											<xsl:variable name="currentObx" select="."/>
											<node>				
												<xsl:attribute name="id" select="generate-id($currentObx)"/>
												<verDT><xsl:value-of select="verificationDateTime"/></verDT>
											</node>			
				</xsl:for-each-group>
			</data>
		</xsl:variable>
		
		<!-- group-by="referenceRange" -->
		<!-- verificationDateTime from newer OBX DMOD -->
		<xsl:variable name="verificationDateTime3">
			<data>
				<xsl:for-each-group select="../../obxLevel/obx[
												history!='true'
												and obxType = $currentOBXType
												and observationId = $currentObservationId
												and ((observationCode = $currentObservationCode) or not($currentObservationCode))
											]" group-by="concat(referenceRange, '-', observationValue, '-', verificationDateTime)">
											
											<xsl:sort select="verificationDateTime" order="descending"/>
											<xsl:variable name="currentObx" select="."/>
											<node>				
												<xsl:attribute name="id" select="generate-id($currentObx)"/>
												<verDT><xsl:value-of select="verificationDateTime"/></verDT>
											</node>			
				</xsl:for-each-group>
			</data>
		</xsl:variable>
		<!-- Remove duplicated results by grouping (RMOD). -->
		<xsl:for-each-group select="../../obxLevel/obx[
											history[not(@modificationType = 'PathologistReview')] = 'true'
											and obxType = $currentOBXType
											and observationId = $currentObservationId
											and ((observationCode = $currentObservationCode) or not($currentObservationCode))
											and (((observationSubId = $observationSubId or not($observationSubId)) and $extendedNteMatch = 'true') or $extendedNteMatch = 'false')
										]" group-adjacent="string(normalize-space(observationValue))">
			<xsl:sort select="verificationDateTime" order="descending"/>
			<xsl:variable name="genIdObx" select="generate-id(.)"/>
			<xsl:choose>
				<xsl:when test="$sendAllRMODs='true'">
					<xsl:apply-templates select="current-group()[1][
																	string(observationValue)
																]" mode="RMOD">
						<xsl:with-param name="currentVerificationDateTime" select="$verificationDateTime2/data/node[@id = $genIdObx]/preceding-sibling::*[1]/verDT"/>
					</xsl:apply-templates>
				</xsl:when>
				<xsl:otherwise>
					<!-- Create RMOD but only when real change occurred. -->
					<xsl:apply-templates select="current-group()[1][
																	string(observationValue)
																	and $currentObservationValue != observationValue
																]" mode="RMOD">
						<xsl:with-param name="currentVerificationDateTime" select="$verificationDateTime2/data/node[@id = $genIdObx]/preceding-sibling::*[1]/verDT"/>
					</xsl:apply-templates>
				</xsl:otherwise>
			</xsl:choose>
			<!-- Create DMOD -->
			<xsl:apply-templates select="current-group()[1][
															$sendDmodComment = 'true'
															and string(referenceRange)
															and string($currentReferenceRange)
															and $currentReferenceRange != referenceRange
														]" mode="DMOD">														
														<xsl:with-param name="currentVerificationDateTime" select="if ($verificationDateTime3/data/node[@id = $genIdObx]/preceding-sibling::*[1]/verDT/text()) 
														then $verificationDateTime3/data/node[@id = $genIdObx]/preceding-sibling::*[1]/verDT else $verificationDateTime3"/>
			</xsl:apply-templates>
		</xsl:for-each-group>
		
		<!-- Get current FCOM/RC value (if doesn't exist will be null). -->
		<xsl:variable name="currentResultComment" select="string(normalize-space(../nteLevel/nte[id = ('FCOM', 'RC')]/comment))"/>
		<xsl:for-each-group select="../../obxLevel[
											obx/history[not(@modificationType = 'PathologistReview')] = 'true'
											and obx/obxType = $currentOBXType
											and obx/observationId = $currentObservationId
											and ((obx/observationCode = $currentObservationCode) or not($currentObservationCode))
											and (((obx/observationSubId = $observationSubId or not($observationSubId)) and $extendedNteMatch = 'true') or $extendedNteMatch = 'false')
										]/nteLevel[
											nte/id = 'FCOM'
											and normalize-space(nte/comment/text())
											and string(normalize-space(nte/comment)) != $currentResultComment
										]" group-by="string(normalize-space(nte/comment))">
			<xsl:sort select="nte/enteredDateTime" order="descending"/>
			<xsl:apply-templates select="current-group()[1]"/>
			<xsl:variable name="genIdObx" select="generate-id(.)"/>
			<xsl:apply-templates select="current-group()[1][string(observationValue) and observationValue != $currentObservationValue]" mode="RMOD">
				<xsl:with-param name="currentVerificationDateTime" select="$verificationDateTime2/data/node[@id = $genIdObx]/preceding-sibling::*[1]/verDT"/>
			</xsl:apply-templates>
		</xsl:for-each-group>
		<xsl:if test="(technology='LAB' and reviewedDocumentation = 'true' and string(reviewedSignature)) or (technology!='LAB' and string(reviewedSignature))">
			<xsl:call-template name="reviewedSignatureELSG"/>
		</xsl:if>
		<xsl:apply-templates select="$calls/call[tests/test = $currentObservationId][$enableExtendedCalledMode='false']"/>
		<xsl:apply-templates select="$calls/call[tests/test/@obrTestCall = 1][$enableExtendedCalledMode='true']"/>
		<xsl:apply-templates select="$calls/call[tests/test = $currentObservationId][tests/test/@obrTestCall != 1][$enableExtendedCalledMode='true']"/>
		<xsl:apply-templates select="$calls/call[tests/test = $currentObservationCode][tests/test != $currentObservationId][tests/test/@obrTestCall != 1][$enableExtendedCalledMode='true']"/>
	</xsl:template>
	<!-- Calls for MIC -->
	<!--<xsl:template match="obx[$isMicroTransaction and history = 'false' and obxType = 'MicTestComment' 
									and (($countTestComponents!=$countCurrentCalledTests and $countTestComponents!=1 and $countCurrentCalledTests!=1) or ($countTestComponents=1 and $countCurrentCalledTests=1) 
									or ($countCurrentCalledTests=$countNotHistoricallCalledTests))]">
		<xsl:copy-of select="."/>
		<xsl:variable name="currentObservationId" select="observationId"/>
		<xsl:apply-templates select="$calls/call[tests/test = $currentObservationId]" />
	</xsl:template>-->
	<xsl:template match="obx[$isMicroTransaction and history = 'false' and obxType = 'MicTestComment']">
		<xsl:copy-of select="."/>
		<xsl:variable name="currentObservationId" select="observationId"/>
		<xsl:apply-templates select="$calls/call[tests/test = $currentObservationId]"/>
	</xsl:template>
	<!--
		The copy template.
	-->
	<xsl:template match="@* | node()">
		<xsl:copy>
			<xsl:apply-templates select="@* | node()"/>
		</xsl:copy>
	</xsl:template>
	<!--
		Downtime scenario - copy SYSTEM to sender code.
	-->
	<xsl:template match="/Message/Event/msg/senderCode[text() = 'ESB_OTCHG']">
		<senderCode>
			<xsl:value-of select="/Message/Event/msg/attributes[name = 'SYSTEM']/value"/>
		</senderCode>
	</xsl:template>
	<!--
           Convert rtf to plain text - comments, cancel reasons, interpretations.
	-->
	<xsl:template match="nteLevel/nte/comment/text()
		| obrLevel/obr/cancellationReason/text()
		| obxLevel/obx/observationValue/text()
		| obxLevel/obx[obxType ='CallInfo']/observationDescription/text()
		| dspLevel/dsp/comment/text()
		| obxLevel/obx/units/text()">
		<xsl:variable name="plainText">
			<xsl:choose>
				<xsl:when test="../../plainTextComment/text()"><xsl:value-of select="../../plainTextComment"/></xsl:when>
				<xsl:when test="../../supplementalValues/value[@n='plainTextObservationValue']/text() and local-name(..)='observationValue'"><xsl:value-of select="../../supplementalValues/value[@n='plainTextObservationValue']"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="rtf:rtf2str(., $rtfSymbolsTable, $txtSymbolsTable)"/></xsl:otherwise>
				<!--<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>-->
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="choppedPlainText">
			<xsl:call-template name="removeFrontEndCarriageReturns">
				<xsl:with-param name="inputString" select="$plainText"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:value-of select="$choppedPlainText"/>
	</xsl:template>
	<!--
		****************************************************************************
		*** Drop matches.
		****************************************************************************
	-->
	<!--
	  Drop historical OBX-es.
	-->
	<xsl:template match="obxLevel[not($isMicroTransaction) and obx/history = 'true' and not(obx/obxType = 'Component') and not(obx/obxType = 'CallInfo')]"/>
	<!--
		Drop Called OBX-es
	-->
	<xsl:template match="obxLevel[obx/obxType = 'CallInfo']"/>
	<!--
		Dropp all empty comments.
	-->
	<xsl:template match="nteLevel[
							not (
								string(normalize-space(nte/comment))
							)
							and
								nte/id != '@L'
						]"/>
	<!--
		Dropp when MODCOM not used.
	-->
	<xsl:template match="nteLevel[
							$sendModcomComment = 'false'
							and nte/history = 'true'
							and matches(nte/id, '(PATCOM|STAYCOM|ORDCOM)')
							and string(normalize-space(nte/comment))
						]"/>
	<!--
		Drop cancelled results comments
	-->
	<xsl:template match="nteLevel[
							nte[id = 'RC']
							and $dropCancelledResComments != '-'
							and ancestor::obxLevel[
									obx[
										history = 'false'
										and observationResultStatus = 'Cancelled'
										and (
											cmn:matchPatern(technology, $dropCancelledResComments, ',')
											or $dropCancelledResComments = 'ALL'
										)
									]
								]
						]">
		<xsl:if test="$generateInfoData">
			<__info__>
				<xsl:value-of select="concat('RC for test obsId(', ../obx/observationId, '), obsCode(', ../obx/observationCode, ') was dropped by dropCancelledResComments')"/>
			</__info__>
		</xsl:if>
	</xsl:template>
	<!--
		The main OBX match.
	-->
	<xsl:template match="obxLevel[
							not($isMicroTransaction)
							and obx/history = 'false'
							and not(obx/obxType = 'CallInfo')
						]">
		<xsl:variable name="currentTid" select="obx/technology"/>
		<xsl:choose>
			<!-- Drop components -->
			<xsl:when test="obx/obxType = 'Component'"/>
			<!-- Drop in all autodefault results (observationMethod = DEFAULT) that are defined in "blockDefaultResult" (regular expresssion) -->
			<xsl:when test="$blockDefaultResults != '-'
							and obx/observationMethod = 'DEFAULT'
							and matches(obx/observationValue, $blockDefaultResults)">
				<xsl:if test="$generateInfoData">
					<__info__>
						<xsl:value-of select="concat('Vale obsValue(', obx/observationValue, ') of auto-defaulted test obsId(', obx/observationId, ') matches to the blocked list [', $blockDefaultResults, ']')"/>
					</__info__>
				</xsl:if>
			</xsl:when>
			<!-- Drop Prompt Test if is blocked for current event.	-->
			<xsl:when test="$blockedPromptTestFor != '-'
							and obx/obxType = 'PromptTest'
							and obx/history = 'false'
							and cmn:matchPatern($event, $blockedPromptTestFor, ',')">
				<xsl:if test="$generateInfoData">
					<__info__>
						<xsl:value-of select="concat('Prompt Tests obsId(', obx/observationId, ') was blocked - current event is on the blocked Prompt Tests events list [', $blockedPromptTestFor, ']')"/>
					</__info__>
				</xsl:if>
			</xsl:when>
			<!-- If at least OBX with technology from blockPendingsTechnologies has Pending status - drop all OBX belonging to this technology.	-->
			<xsl:when test="$blockPendingsTechnologies != '-'
							and obx/obxType != 'Component'
							and cmn:matchPatern(obx/technology, $blockPendingsTechnologies, ',')
							and exists(
									../obxLevel[
										obx/observationResultStatus = 'Pending' 
										and obx/technology = $currentTid
									]
								)">
				<xsl:if test="$generateInfoData">
					<__info__>
						<xsl:value-of select="concat('Result for obsId(', obx/observationId, '), obsCode(', obx/observationCode, ') was blocked - ', obx/technology, ' technology is on the blocked pending technologies list [', $blockPendingsTechnologies ,']')"/>
					</__info__>
				</xsl:if>
			</xsl:when>
			<!-- Drop OBX without Pathologist Review. -->
			<xsl:when test="$dropResultsWithoutPathologistReview != '-'
							and matches(obx/obxType, '(Result|PromptTest)')
							and matches($event, '(TEST_RELEASED|TEST_RESEND|ORDER_RESEND)')
							and obx/supplementalValues/value[@n = 'NotReportableWithoutReview'] = 'true'
							and obx/supplementalValues/value[@n = 'ReviewRequired'] = 'true'
							and not(string(obx/reviewedDateTime))
							and cmn:matchPatern(obx/technology, $dropResultsWithoutPathologistReview, ',')">
				<xsl:if test="$generateInfoData">
					<__info__>
						<xsl:value-of select="concat('Result for obsCode(', obx/observationCode, '), obsId(', obx/observationId, ') was blocked - no Pathologist Review for ', obx/technology, ' technology - the blocked list [', $dropResultsWithoutPathologistReview, ']')"/>
					</__info__>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<obxLevel>
					<!-- Apply templates for obx and any comments under current obxLevel. -->
					<xsl:apply-templates/>
				</obxLevel>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- copy value from Component ( before drop ) -->
	<xsl:template match="//obxLevel/obx[obxType='TestInfo' and history='false' and section='TestHeader' and systemCode='IWS']/observationValue">
	<observationValue>
		<xsl:choose>
			<xsl:when test="//obxLevel/obx[obxType='Component' and technology='IWS' and history='false']/observationValue/text()"><xsl:value-of select="//obxLevel/obx[obxType='Component' and technology='IWS' and history='false']/observationValue/text()" /></xsl:when>
			<xsl:otherwise><xsl:value-of select="." /></xsl:otherwise>
		</xsl:choose>
	</observationValue>	
	</xsl:template>	

	<!-- copy LIS read from GI to attributes -->
    <xsl:template match="//attributes[ name='LIS' ]/value/text()" >
        <xsl:value-of select="//ReportableComponents/GI_TREL_HISTESTINFO_OBJ/LIS" />
    </xsl:template> 
	
	<!-- for BB copy autID and create autUID -->
	<xsl:template match="@autID">
		<xsl:copy-of select="."/>
		<xsl:attribute name="autUID" select="."/>
	</xsl:template>
	
	<!-- for BB copy facID and create facUID -->
	<xsl:template match="@facID">
		<xsl:copy-of select="."/>
		<xsl:attribute name="facUID" select="."/>
	</xsl:template>

	<xsl:template match="Event/msg">
		 <xsl:element name="msg">
			<xsl:copy-of select="@* | node()"/>
			<xsl:if test="$waitForParentHIS = 'false' and (//Message/ParentOrders/errCode != '0' or //Message/ParentOrders/GI_TREL_HISTESTINFO_OBJ/ORDNUM = '-1') and (number($try) = number($maxTrySecondVal) or number($try) &gt; number($maxTrySecondVal))">
				 <xsl:sequence xmlns:nm="java:com.scc.smx.components.saxon.utils.NormalizedMessageUtil" select="nm:setPropertyStr('waitForParentHIS', 'false')"/>
			 </xsl:if>
		 </xsl:element>
	</xsl:template>

	<!--
		****************************************************************************
		*** The main match.
		****************************************************************************
	-->
	<xsl:template match="/">
		<xsl:apply-templates/>
	</xsl:template>
</xsl:stylesheet>