<!-- $Id: prepNewTestRequest.xslt 11812 2022-05-16 07:52:42Z rafalpa $  -->
<xsl:stylesheet version="2.0" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:ns0="http://mom.scc.com/" xmlns:ns2="http://mom.scc.com/" xmlns:res="http://www.softcomputer.com/ResultsReceiving/" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fun="http://interfaces_function.com" xmlns:ns4="http://www.softcomputer.com/SoftGeneOrderingService/" xmlns:ns5="http://www.softcomputer.com/RequisitionOrderingService/" xmlns:cmn="http://www.softcomputer.com/COMMON/RROutService">
	<xsl:output encoding="UTF-8" indent="yes" method="xml" version="1.0" exclude-result-prefixes="#all"/>
	<!-- Parameters -->
	<xsl:param name="externalURL">${externalURL}</xsl:param>
	<!-- Variables -->
	<xsl:variable name="pid" select="join/Message/Data/msg1/pidLevel/pid"/>
	<xsl:variable name="testId" select="if (//msg/attributes[name='TEST']/value/text()) then //msg/attributes[name='TEST']/value else 
										/join/Message/Data/msg1/pidLevel/pv1Level/orcLevel/obrLevel/obr/testId"/>
	<xsl:variable name="corrid" select="//msg/attributes[name='CORRID']/value"/>
	<xsl:variable name="obrLevel" select="/join/Message/Data/msg1/pidLevel/pv1Level/orcLevel/obrLevel"/>
	<xsl:variable name="sampleId" select="if ($obrLevel/spmLevel[sacLevel/sac/tubeBarcode[@source='externalTubeId']]) then
											  $obrLevel/spmLevel[sacLevel/sac/tubeBarcode[@source='externalTubeId']][1]/sacLevel[sac/tubeBarcode[@source='externalTubeId']/text()][1]/sac/tubeBarcode[@source='externalTubeId'] else 
	                                          $obrLevel/spmLevel[spm/specimenBarcode/text()][1]/spm[specimenBarcode/text()][1]/specimenBarcode"/>
	<xsl:variable name="destMsgId" select="/join/Message/Event/msg/destMsgId"/>
	<xsl:variable name="tz" select="format-dateTime(current-dateTime(),'[Z0001]')"/>
	<xsl:variable name="sendDate" select="fun:dateTimeZone(/join/Message/Event/msg/sendDate)"/>
	<xsl:variable name="transactionDate" select="if (string($obrLevel/obr/transactionDate/@odt)) then $obrLevel/obr/transactionDate/@odt else fun:dateTimeZone($obrLevel/obr/transactionDate)"/>
	<xsl:variable name="token" as="xs:string">${!DICT.LABTEK_B}</xsl:variable>
	<xsl:variable name="method" as="xs:string">POST</xsl:variable>
	<!-- Main match -->
	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="not(/join/Message/ReportableComponents/errCode='0') and not(/join/Message/Header/Route='newTest')">
				<xsl:element name="skip">
					<xsl:attribute name="source"><xsl:value-of select="'GI'"/></xsl:attribute>
					<xsl:attribute name="details"><xsl:value-of select="/join/Message/ReportableComponents/err"/></xsl:attribute>
					<xsl:attribute name="status"><xsl:value-of select="'1'"/></xsl:attribute>
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<xsl:element name="Message">
					<xsl:attribute name="contentType">application/json;charset=UTF-8</xsl:attribute>
					<xsl:attribute name="method" select="$method"/>
					<xsl:attribute name="resource" select="$externalURL"/>
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
							<xsl:call-template name="patient"/>
							<xsl:call-template name="order"/>
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
	<xsl:template name="order" exclude-result-prefixes="#all">
		<order class="object">
			<xsl:copy-of select="fun:element($sampleId,'sampleId')"/>
			<xsl:copy-of select="fun:element($testId,'testId')"/>
			<xsl:copy-of select="fun:element($corrid,'hisNumber')"/>
			<xsl:copy-of select="fun:element($transactionDate,'actionDT')"/>
		</order>
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
		<xsl:value-of select="concat(substring(xs:string($source),1,19), $tz)"/>
	</xsl:function>
</xsl:stylesheet>
