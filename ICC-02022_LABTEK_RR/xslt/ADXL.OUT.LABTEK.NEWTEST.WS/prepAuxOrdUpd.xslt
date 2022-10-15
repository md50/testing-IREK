<?xml version="1.0" encoding="utf-8"?>
<!-- $Id: prepAuxOrdUpd.xslt 11045 2022-01-05 22:30:12Z rafalpa $  -->
<!-- ADXL.OUT.LABTEK.NEWTEST.WS store HIS# in GI -->
<xsl:stylesheet version="2.0" xmlns:nm="java:com.scc.smx.components.saxon.utils.NormalizedMessageUtil" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:saxon="http://saxon.sf.net/">
	<xsl:output method="xml" indent="yes"/>
	<xsl:variable name="extractedMsg" select="if(//msgText/text()) then saxon:parse(//msgText)/Message/Data/* else ''"/>
	<xsl:variable name="obrLevel" select="$extractedMsg//obrLevel"/>
	<xsl:variable name="mrn" select="if (//msg/attributes[name='MRN']/value/text()) then //msg/attributes[name='MRN']/value else $extractedMsg//pidLevel/pid/sccMrn"/>
	<xsl:variable name="billing" select="if (//msg/attributes[name='BILLING']/value/text()) then //msg/attributes[name='BILLING']/value else $extractedMsg//pv1Level/pv1/preadmitNumber"/>
	<xsl:variable name="order" select="if (//msg/attributes[name='ORDER']/value/text()) then //msg/attributes[name='ORDER']/value else $extractedMsg//orcLevel/orc/sccOrderNumber"/>
	<xsl:variable name="barcode" select="if (//msg/attributes[name='AUXILIARY_ORDER']/value/text()) then //msg/attributes[name='AUXILIARY_ORDER']/value else 
										 if ($obrLevel/spmLevel[sacLevel/sac/tubeBarcode[@source='externalTubeId']]) then
											 $obrLevel/spmLevel[sacLevel/sac/tubeBarcode[@source='externalTubeId']][1]/sacLevel[sac/tubeBarcode[@source='externalTubeId']/text()][1]/sac/tubeBarcode[@source='externalTubeId'] else 
	                                            $obrLevel/spmLevel[spm/specimenBarcode/text()][1]/spm[specimenBarcode/text()][1]/specimenBarcode						 "/>
	<xsl:template match="/">
		<SubmitOrder xmlns="http://www.softcomputer.com/GeneOrderingService/">
			<orderRequisition>
				<xsl:call-template name="createSec"/>
				<Patient xmlns="http://www.softcomputer.com/SoftGeneOrderingService/">
					<MRN>
						<xsl:value-of select="$mrn"/>
					</MRN>
				</Patient>
				<Visit xmlns="http://www.softcomputer.com/SoftGeneOrderingService/">
					<BillingNum>
						<xsl:value-of select="$billing"/>
					</BillingNum>
				</Visit>
				<Order xmlns="http://www.softcomputer.com/SoftGeneOrderingService/">
					<AuxiliaryOrder>
						<xsl:value-of select="$barcode"/>
					</AuxiliaryOrder>
					<OrderNumber>
						<xsl:value-of select="$order"/>
					</OrderNumber>
					<OrderOperation>Update</OrderOperation>
				</Order>
			</orderRequisition>
		</SubmitOrder>
	</xsl:template>
	<!--..........................CREATE SECURITY SECTION ....................... -->
	<xsl:template name="createSec">
		<Sec xmlns="http://www.softcomputer.com/SoftGeneOrderingService/">
			<System xmlns="http://www.softcomputer.com/CommonTypes/">ADXL</System>
			<UserID xmlns="http://www.softcomputer.com/CommonTypes/">SCC</UserID>
			<Terminal xmlns="http://www.softcomputer.com/CommonTypes/">PRNEC</Terminal>
		</Sec>
	</xsl:template>
</xsl:stylesheet>
