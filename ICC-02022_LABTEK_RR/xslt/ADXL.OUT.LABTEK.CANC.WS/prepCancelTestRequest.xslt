<!-- $Id: prepCancelTestRequest.xslt 11813 2022-05-16 08:23:00Z rafalpa $  -->
<!-- ADXL.OUT.LABTEK.CANC.WS -->
<xsl:stylesheet version="2.0" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:ns0="http://mom.scc.com/" xmlns:ns2="http://mom.scc.com/" xmlns:res="http://www.softcomputer.com/ResultsReceiving/" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fun="http://interfaces_function.com" xmlns:cmn="http://www.softcomputer.com/COMMON/RROutService">
	<xsl:output encoding="UTF-8" indent="yes" method="xml" version="1.0" exclude-result-prefixes="#all"/>
	<!-- Parameters -->
	<xsl:param name="externalURL">${externalURL}</xsl:param>
	<!-- Variables -->
	<xsl:variable name="extractedMsg" select="if(//msgText/text()) then saxon:parse(//msgText)/Message/Data/* else ''"/>
	<xsl:variable name="pid" select="$extractedMsg//pid"/>
	<xsl:variable name="testId" select="if (//msg/attributes[name='TEST']/value/text()) then //msg/attributes[name='TEST']/value else $extractedMsg//obrLevel[1]/obr/testId"/>
	<xsl:variable name="corrid" select="//msg/attributes[name='CORRID']/value"/>
	<xsl:variable name="obrLevel" select="$extractedMsg//obrLevel"/>
	<xsl:variable name="sampleId" select="if ($obrLevel/spmLevel[sacLevel/sac/tubeBarcode[@source='externalTubeId']]) then
											  $obrLevel/spmLevel[sacLevel/sac/tubeBarcode[@source='externalTubeId']][1]/sacLevel[sac/tubeBarcode[@source='externalTubeId']/text()][1]/sac/tubeBarcode[@source='externalTubeId'] else 
	                                          $obrLevel/spmLevel[spm/specimenBarcode/text()][1]/spm[specimenBarcode/text()][1]/specimenBarcode"/>
	<xsl:variable name="destMsgId" select="/*:onMessage/msg/destMsgId"/>
	<xsl:variable name="tz" select="format-dateTime(current-dateTime(),'[Z0001]')"/>
	<xsl:variable name="sendDate" select="fun:dateTimeZone(/*:onMessage/msg/sendDate)"/>
	<xsl:variable name="cancellationDate" select="if (string($obrLevel/obr/cancellationDate/@odt)) then $obrLevel/obr/cancellationDate/@odt else fun:dateTimeZone($obrLevel/obr/cancellationDate)"/>
	<xsl:variable name="token" as="xs:string">${!DICT.LABTEK_B}</xsl:variable>
	<xsl:variable name="method" as="xs:string">POST</xsl:variable>
	<!-- Main match -->
	<xsl:template match="/">
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
			<xsl:copy-of select="fun:element($cancellationDate,'actionDT')"/>
			<!-- cancellation data -->
			<xsl:copy-of select="fun:element($obrLevel/obr/statusReason,'cancelReasonCode')"/>
			<xsl:copy-of select="fun:element($obrLevel/obr/statusReason/@text,'cancelReasonDesc')"/>
			<xsl:copy-of select="fun:element($obrLevel/obr/cancellationReason,'cancelComment')"/>
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
