<!-- $Id: prepResultRequest.xslt 12142 2022-07-14 16:57:16Z rafalpa $  -->
<xsl:stylesheet version="2.0" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:ns0="http://mom.scc.com/" 
xmlns:ns2="http://mom.scc.com/" xmlns:res="http://www.softcomputer.com/ResultsReceiving/" xmlns:saxon="http://saxon.sf.net/" 
xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
xmlns:fun="http://interfaces_function.com" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
	<xsl:output encoding="UTF-8" indent="yes" method="xml" version="1.0" exclude-result-prefixes="#all"/>
	<!-- Parameters -->
	<xsl:param name="allowNoResultsForRE">${allowNoResultsForRE}</xsl:param>
	<!--<xsl:param name="allowNoResultsForRE">false</xsl:param>-->
	<xsl:param name="externalURL">${externalURL}</xsl:param>
	<!-- INTERNAL parameters -->
	<xsl:param name="sendOrderLevelUdfs">true</xsl:param>
	<xsl:param name="sendSpecimenLevelUdfs">true</xsl:param>
	
	<!-- Variables -->
	<xsl:variable name="extractedMsg" select="//Message/Data/msg1"/>
	<xsl:variable name="pid" select="$extractedMsg//pid"/>
	<xsl:variable name="testId" select="if (//msg/attributes[name='TEST']/value/text()) then //msg/attributes[name='TEST']/value else $extractedMsg//obrLevel[1]/obr/testId"/>
	<xsl:variable name="corrid" select="//msg/attributes[name='CORRID']/value"/>
	<xsl:variable name="event" select="if (//Message/Event/msg/eventCode/text()) then //Message/Event/msg/eventCode else //msg/attributes[name='EVENT']/value"/>
	<xsl:variable name="orcLevel" select="$extractedMsg//orcLevel"/>
	<xsl:variable name="obrLevel" select="$extractedMsg//obrLevel[obr/testId=$testId]"/>
	<xsl:variable name="sampleId" select="if ($obrLevel/spmLevel[sacLevel/sac/tubeBarcode[@source='externalTubeId']]) then
											  $obrLevel/spmLevel[sacLevel/sac/tubeBarcode[@source='externalTubeId']][1]/sacLevel[sac/tubeBarcode[@source='externalTubeId']/text()][1]/sac/tubeBarcode[@source='externalTubeId'] else 
	                                          $obrLevel/spmLevel[spm/specimenBarcode/text()][1]/spm[specimenBarcode/text()][1]/specimenBarcode"/>
	<xsl:variable name="reactivationComment" select="$extractedMsg//obrLevel[obr/testId=$testId]/obxLevel/obx[obxType='Report' and history='false']/supplementalValues/value[@n='reactivationReasonComment']"/>
	<xsl:variable name="destMsgId" select="if (//Message/Event/msg/destMsgId/text()) then //Message/Event/msg/destMsgId else //msg/attributes[name='DESTMSGID']/value"/>
	<xsl:variable name="sendDate" select="fun:dateTimeZone(//Message/Event/msg/sendDate)"/>
	<xsl:variable name="method" as="xs:string">POST</xsl:variable>
	<xsl:variable name="token" as="xs:string">${!DICT.LABTEK_B}</xsl:variable>
	<xsl:variable name="arrayResult" as="xs:boolean" select="exists($obrLevel/obxLevel[obx/obxType='Result' and obx/observationSubId/text() and obx/observationSubId/@hisArrayRowId='true' and obx/history='false' and obx/results/toHIS='true' and obx/observationValue/text()])"/>
	<xsl:variable name="nonArrayResult" as="xs:boolean" select="exists($obrLevel/obxLevel[obx/obxType='Result' and obx/history='false' and obx/results/toHIS='true' and obx/observationValue/text()])"/>
	<xsl:variable name="tz" select="format-dateTime(current-dateTime(),'[Z0001]')"/>
	<xsl:variable name="diagnosticDelivery" select="//diagnosticDelivery"/>
	<!-- Main match -->
	<xsl:template match="/">
		<!--<xsl:message>
		arrayResultFound:[<xsl:value-of select="$arrayResult"/>]
		nonArrayResultFound:[<xsl:value-of select="$nonArrayResult"/>]
		</xsl:message>-->
		<xsl:choose>
			<xsl:when test="not($arrayResult) and not($nonArrayResult) and $allowNoResultsForRE='false'">
				<xsl:element name="skip">
					<xsl:attribute name="status" select="'9'"/>
					<xsl:attribute name="details" select="'There are no results to be reported to LabTek.'"/>
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<xsl:element name="Message">
					<xsl:attribute name="contentType">application/json;charset=UTF-8</xsl:attribute>
					<xsl:attribute name="method" select="$method"/>
					<xsl:attribute name="resource" select="if ($diagnosticDelivery='true') then 'diagnosticDelivery' else $externalURL"/>
					<xsl:attribute name="server_tz" select="$tz"/>
					<xsl:element name="Header">
						<xsl:element name="Instance">JSON</xsl:element>
						<xsl:element name="Source">JSON</xsl:element>
						<xsl:element name="Authorization">
							<xsl:value-of select="concat('Bearer ',$token)"/>
						</xsl:element>
					</xsl:element>
					<xsl:element name="Data">
						<xsl:element name="root">
							<xsl:copy-of select="fun:element($sendDate,'timestamp')"/>
							<xsl:copy-of select="fun:element($destMsgId,'transactionId')"/>
							<xsl:copy-of select="fun:element(if ($event='TEST_RELEASED') then 'false' else 'true','resend')"/>
							<xsl:call-template name="patient"/>
							<xsl:element name="order">
								<xsl:attribute name="class" select="'object'"/>
								<xsl:copy-of select="fun:element($sampleId,'sampleId')"/>
								<xsl:copy-of select="fun:element($testId,'testId')"/>
								<xsl:copy-of select="fun:element($corrid,'hisNumber')"/>
								<xsl:copy-of select="fun:element($reactivationComment,'reactivationComment')"/>
								<!--<xsl:if test="exists($obrLevel/obxLevel[obx/obxType='TestInfo' and obx/observationId='CANNEDMESSAGE' and obx/observationCode=$obrLevel/obr/testId]/nteLevel[nte/id=('DISCLAIMERCANNEDMESSAGE','REFERENCECANNEDMESSAGE','METHODCANNEDMESSAGE')]/nte/comment/text())">
									<xsl:element name="resultComment">
										<xsl:value-of select="string-join($obrLevel/obxLevel[obx/obxType='TestInfo' and obx/observationId='CANNEDMESSAGE' and obx/observationCode=$obrLevel/obr/testId]/nteLevel[nte/id=('DISCLAIMERCANNEDMESSAGE','REFERENCECANNEDMESSAGE','METHODCANNEDMESSAGE')]/nte/comment,'&#10;')"/>
									</xsl:element>
								</xsl:if>-->
								<xsl:if test="$nonArrayResult">
									<xsl:element name="results">
										<xsl:attribute name="class" select="'array'"/>
										<!-- send results and interpretations -->
										<xsl:for-each select="$obrLevel/obxLevel[obx/obxType=('Result','Interpretation') and not(obx/observationSubId/text()) and not(starts-with(obx/observationId,'{')) and obx/history='false' and obx/results/toHIS='true' and obx/observationValue/text()]">
											<xsl:call-template name="results">
												<xsl:with-param name="obxType" select="obx/obxType"/>
											</xsl:call-template>
										</xsl:for-each>
										<!-- send order level UDF's (orcLevel/zmoLevel) controlled by internal parameter -->
										<xsl:if test="$sendOrderLevelUdfs='true'">
											<xsl:for-each select="$orcLevel/zmoLevel/zmo[(history='false' or not(history)) and reportableToHIS='true' and value/text()]">
												<xsl:call-template name="udfResults">
													<xsl:with-param name="source" select="."/>
												</xsl:call-template>
											</xsl:for-each>
										</xsl:if>
										<!-- send specimen level UDF's (obrLevel/spmLevel/zmuLevel) controlled by internal parameter -->
										<xsl:if test="$sendSpecimenLevelUdfs='true'">
											<xsl:for-each select="$obrLevel/spmLevel/zmuLevel/zmu[(history='false' or not(history)) and reportableToHIS='true' and value/text()]">
												<xsl:call-template name="udfResults">
													<xsl:with-param name="source" select="."/>
												</xsl:call-template>
											</xsl:for-each>
										</xsl:if>
										<!-- send non array results treated like array (group by X -> if observationId contains {X} ) -->
										<xsl:for-each-group select="$obrLevel/obxLevel[obx/obxType='Result' and not(obx/observationSubId/text()) and starts-with(obx/observationId,'{') and obx/history='false' and obx/results/toHIS='true' and obx/observationValue/text()]" group-by="substring-before(substring-after(obx/observationId,'{'),'}')">
											<xsl:variable name="codeId" select="substring-before(substring-after(obx/observationId,'{'),'}')"/>
											<xsl:call-template name="resultsNonArray">
												<xsl:with-param name="codeId" select="$codeId"/>
											</xsl:call-template>
										</xsl:for-each-group>
									</xsl:element>
								</xsl:if>
								<!-- send array results -->
								<xsl:for-each-group select="$obrLevel/obxLevel[obx/obxType='Result' and obx/observationSubId/text() and obx/observationSubId/@hisArrayRowId='true' and obx/history='false' and obx/results/toHIS='true' and obx/observationValue/text()]" group-by="obx/observationSubId">
									<xsl:variable name="observationSubId" select="obx/observationSubId"/>
									<xsl:element name="results">
										<xsl:attribute name="class" select="'array'"/>
										<xsl:call-template name="resultsArray">
											<xsl:with-param name="observationSubId" select="$observationSubId"/>
										</xsl:call-template>
									</xsl:element>
								</xsl:for-each-group>
							</xsl:element>
						</xsl:element>
					</xsl:element>
				</xsl:element>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- Templates -->
	<xsl:template name="patient" exclude-result-prefixes="#all">
		<patient class="object">
			<xsl:copy-of select="fun:element($pid/sccMrn,'patientId')"/>
		</patient>
	</xsl:template>
	<xsl:template name="resultsArray">
		<xsl:param name="observationSubId"/>
		<xsl:attribute name="class" select="'object'"/>
		<xsl:variable name="correctionStatus" as="xs:boolean" select="exists($obrLevel/obxLevel[obx/obxType='Result' and obx/observationSubId=$observationSubId and obx/observationSubId/@hisArrayRowId='true' and obx/history='false' and obx/results/toHIS='true' and obx/observationValue/text() and obx/correctionStatus='Corrected'])"/>
		<xsl:variable name="observationDT">
			<xsl:for-each select="$obrLevel/obxLevel[obx/obxType='Result' and obx/observationSubId=$observationSubId and obx/observationSubId/@hisArrayRowId='true' and obx/history='false' and obx/results/toHIS='true' and obx/observationValue/text()]/obx/observationDateTime">
				<xsl:element name="observationDateTime">
					<xsl:value-of select="if (string(./@odt)) then ./@odt else substring(.,1,19)"/>
				</xsl:element>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="maxObservationDT" as="xsd:dateTime*" select="max($observationDT/observationDateTime/xsd:dateTime(.))"/>
		<xsl:variable name="verificationDT">
			<xsl:for-each select="$obrLevel/obxLevel[obx/obxType='Result' and obx/observationSubId=$observationSubId and obx/observationSubId/@hisArrayRowId='true' and obx/history='false' and obx/results/toHIS='true' and obx/observationValue/text()]/obx/verificationDateTime">
				<xsl:element name="verificationDateTime">
					<xsl:value-of select="if (string(./@odt)) then ./@odt else substring(.,1,19)"/>
				</xsl:element>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="maxVerificationDT" as="xsd:dateTime*" select="max($verificationDT/verificationDateTime/xsd:dateTime(.))"/>
		<xsl:copy-of select="fun:element(obx/observationSubId,'codeId')"/>
		<!--<xsl:copy-of select="fun:element(obx/?,'codeDesc')"/>-->
		<xsl:copy-of select="fun:element(if ($correctionStatus) then 'Corrected' else obx/observationResultStatus,'resultStatus')"/>
		<xsl:copy-of select="fun:element(fun:dateTimeZone($maxObservationDT),'observationDT')"/>
		<xsl:call-template name="verifiedBy">
			<xsl:with-param name="source" select="obx/verifiedBy"/>
		</xsl:call-template>
		<xsl:copy-of select="fun:element(fun:dateTimeZone($maxVerificationDT),'verificationDT')"/>
		<xsl:element name="attributes">
			<xsl:attribute name="class" select="'array'"/>
			<xsl:for-each select="$obrLevel/obxLevel[obx/obxType='Result' and obx/observationSubId=$observationSubId and obx/observationSubId/@hisArrayRowId='true' and obx/history='false' and obx/results/toHIS='true' and obx/observationValue/text()]">
				<xsl:element name="e">
					<xsl:copy-of select="fun:element(obx/observationId,'key')"/>
					<xsl:copy-of select="fun:element(obx/observationDescription,'description')"/>
					<xsl:copy-of select="fun:element(obx/observationValue,'value')"/>
				</xsl:element>
			</xsl:for-each>
		</xsl:element>
	</xsl:template>
	<xsl:template name="resultsNonArray">
		<xsl:param name="codeId"/>
		<xsl:message>nonArrayLikeArrays: [<xsl:value-of select="$codeId"/>]</xsl:message>
		<xsl:element name="e">
			<xsl:attribute name="class" select="'object'"/>
			<xsl:variable name="obxLevelNode" select="$obrLevel/obxLevel[obx/obxType='Result' and starts-with(obx/observationId,concat('{',$codeId,'}_')) and not(obx/observationSubId/text()) and obx/history='false' and obx/results/toHIS='true' and obx/observationValue/text()]"/>
			<xsl:variable name="correctionStatus" as="xs:boolean" select="exists($obrLevel/obxLevel[obx/obxType='Result' and starts-with(obx/observationId,concat('{',$codeId,'}_')) and not(obx/observationSubId/text()) and obx/history='false' and obx/results/toHIS='true' and obx/observationValue/text() and obx/correctionStatus='Corrected'])"/>
			<xsl:variable name="observationDT">
				<xsl:for-each select="$obxLevelNode/obx/observationDateTime">
					<xsl:element name="observationDateTime">
						<xsl:value-of select="if (string(./@odt)) then ./@odt else substring(.,1,19)"/>
					</xsl:element>
				</xsl:for-each>
			</xsl:variable>
			<xsl:variable name="maxObservationDT" as="xsd:dateTime*" select="max($observationDT/observationDateTime/xsd:dateTime(.))"/>
			<xsl:variable name="verificationDT">
				<xsl:for-each select="$obxLevelNode/obx/verificationDateTime">
					<xsl:element name="verificationDateTime">
						<xsl:value-of select="if (string(./@odt)) then ./@odt else substring(.,1,19)"/>
					</xsl:element>
				</xsl:for-each>
			</xsl:variable>
			<xsl:variable name="maxVerificationDT" as="xsd:dateTime*" select="max($verificationDT/verificationDateTime/xsd:dateTime(.))"/>
			<xsl:copy-of select="fun:element($codeId,'codeId')"/>
			<!--<xsl:copy-of select="fun:element(obx/?,'codeDesc')"/>-->
			<xsl:copy-of select="fun:element(if ($correctionStatus) then 'Corrected' else obx/observationResultStatus,'resultStatus')"/>
			<xsl:copy-of select="fun:element(fun:dateTimeZone($maxObservationDT),'observationDT')"/>
			<xsl:call-template name="verifiedBy">
				<xsl:with-param name="source" select="obx/verifiedBy"/>
			</xsl:call-template>
			<xsl:copy-of select="fun:element(fun:dateTimeZone($maxVerificationDT),'verificationDT')"/>
			<xsl:element name="attributes">
				<xsl:attribute name="class" select="'array'"/>
				<xsl:for-each select="$obxLevelNode">
					<xsl:element name="e">
						<xsl:attribute name="class" select="'object'"/>
						<xsl:copy-of select="fun:element(substring-after(obx/observationId,'}_'),'key')"/>
						<xsl:copy-of select="fun:element(obx/observationDescription,'description')"/>
						<xsl:copy-of select="fun:element(obx/observationValue,'value')"/>
						<!--<xsl:copy-of select="fun:element(obx/repNormalRanges/@text,'normalRange')"/>
						<xsl:copy-of select="fun:element(obx/abnormalFlags,'abnFlag')"/>-->
						<!--<xsl:if test="exists(nteLevel[nte/id=('RMOD','RC','MODCOT')]/nte/comment/text())">
							<xsl:element name="resultComment">
								<xsl:value-of select="string-join(nteLevel[nte/id=('RMOD','RC','MODCOT')]/nte/comment,'&#10;')"/>
							</xsl:element>
						</xsl:if>-->
					</xsl:element>
				</xsl:for-each>
			</xsl:element>
		</xsl:element>
	</xsl:template>
	<xsl:template name="results">
		<xsl:param name="obxType"/>
		<xsl:element name="e">
			<xsl:attribute name="class" select="'object'"/>
			<xsl:copy-of select="fun:element(obx/observationId,'codeId')"/>
			<xsl:copy-of select="fun:element(obx/observationDescription,'codeDesc')"/>
			<xsl:copy-of select="fun:element(if (obx/correctionStatus/text()) then obx/correctionStatus else obx/observationResultStatus,'resultStatus')"/>
			<xsl:copy-of select="fun:element(if (string(obx/observationDateTime/@odt)) then obx/observationDateTime/@odt else fun:dateTimeZone(obx/observationDateTime),'observationDT')"/>
			<xsl:call-template name="verifiedBy">
				<xsl:with-param name="source" select="obx/verifiedBy"/>
			</xsl:call-template>
			<xsl:copy-of select="fun:element(if (string(obx/verificationDateTime/@odt)) then obx/verificationDateTime/@odt else fun:dateTimeZone(obx/verificationDateTime),'verificationDT')"/>
			<xsl:element name="attributes">
				<xsl:attribute name="class" select="'array'"/>
				<xsl:element name="e">
					<xsl:copy-of select="fun:element('RESULT','key')"/>
					<xsl:copy-of select="fun:element(obx/observationValue,'value')"/>
					<!--<xsl:if test="exists(nteLevel[nte/id=('RMOD')]/nte/comment/text())">
						<xsl:element name="resultComment">
							<xsl:value-of select="string-join(nteLevel[nte/id=('RMOD')]/nte/comment,'&#10;')"/>
						</xsl:element>
					</xsl:if>-->
				</xsl:element>
				<!--<xsl:if test="obx/referenceRange/text()">
					<xsl:element name="e">
						<xsl:copy-of select="fun:element('NORMAL_RANGE','key')"/>
						<xsl:copy-of select="fun:element(obx/referenceRange,'value')"/>
					</xsl:element>
				</xsl:if>
				<xsl:if test="obx/abnormalFlags/text()">
					<xsl:element name="e">
						<xsl:copy-of select="fun:element('ABNORMAL_FLAG','key')"/>
						<xsl:copy-of select="fun:element(obx/abnormalFlags,'value')"/>
					</xsl:element>
				</xsl:if>-->
			</xsl:element>
		</xsl:element>
	</xsl:template>
	<xsl:template name="udfResults">
		<xsl:param name="source"/>
		<xsl:element name="e">
			<xsl:attribute name="class" select="'object'"/>
			<xsl:copy-of select="fun:element($source/id,'codeId')"/>
			<xsl:copy-of select="fun:element($source/name,'codeDesc')"/>
			<xsl:copy-of select="fun:element(if ($source/correctionStatus/text()) then $source/correctionStatus else 'Final','resultStatus')"/>
			<xsl:copy-of select="fun:element(if (string($source/enteredDateTime/@odt)) then $source/enteredDateTime/@odt else fun:dateTimeZone($source/enteredDateTime),'observationDT')"/>
			<xsl:call-template name="verifiedBy">
				<xsl:with-param name="source" select="$source/enteredBy"/>
			</xsl:call-template>
			<xsl:copy-of select="fun:element(if (string($source/enteredDateTime/@odt)) then $source/enteredDateTime/@odt else fun:dateTimeZone($source/enteredDateTime),'verificationDT')"/>
			<xsl:element name="attributes">
				<xsl:attribute name="class" select="'array'"/>
				<xsl:element name="e">
					<xsl:copy-of select="fun:element('RESULT','key')"/>
					<xsl:copy-of select="fun:element($source/value,'value')"/>
				</xsl:element>
				<!--<xsl:if test="$source/referenceRange/text()">
					<xsl:element name="e">
						<xsl:copy-of select="fun:element('NORMAL_RANGE','key')"/>
						<xsl:copy-of select="fun:element($source/referenceRange,'value')"/>
					</xsl:element>
				</xsl:if>
				<xsl:if test="$source/abnormalFlags/text()">
					<xsl:element name="e">
						<xsl:copy-of select="fun:element('ABNORMAL_FLAG','key')"/>
						<xsl:copy-of select="fun:element($source/abnormalFlags,'value')"/>
					</xsl:element>
				</xsl:if>-->
			</xsl:element>
		</xsl:element>
	</xsl:template>
	<xsl:template name="verifiedBy">
		<xsl:param name="source"/>
		<xsl:if test="$source/employeeId/text() or $source/doctorName/lastName/text() or $source/doctorName/firstName/text()">
			<xsl:element name="verifiedBy">
				<xsl:attribute name="class" select="'object'"/>
				<xsl:copy-of select="fun:element($source/employeeId,'codeId')"/>
				<xsl:copy-of select="fun:element($source/doctorName/lastName,'lastName')"/>
				<xsl:copy-of select="fun:element($source/doctorName/firstName,'firstName')"/>
			</xsl:element>
		</xsl:if>
	</xsl:template>
	<xsl:function name="fun:element">
		<xsl:param name="source"/>
		<xsl:param name="targetName"/>
		<xsl:if test="string($source)">
			<xsl:element name="{$targetName}">
				<xsl:value-of select="$source"/>
			</xsl:element>
		</xsl:if>
	</xsl:function>
	<xsl:function name="fun:dateTimeZone">
		<xsl:param name="source"/>
		<xsl:value-of select="if (string-length(xs:string($source))=25) then $source else concat(substring(xs:string($source),1,19), $tz)"/>
	</xsl:function>
</xsl:stylesheet>
