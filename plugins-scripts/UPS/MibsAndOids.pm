$UPS::Device::mib_ids = {
  'UPSV4-MIB' => '1.3.6.1.4.1.2254.2.4',
};

$UPS::Device::mibs_and_oids = {
  'MIB-II' => {
      sysDescr => '1.3.6.1.2.1.1.1',
      sysObjectID => '1.3.6.1.2.1.1.2',
      sysUpTime => '1.3.6.1.2.1.1.3',
      sysName => '1.3.6.1.2.1.1.5',
  },
  'IFMIB' => {
      ifTable => '1.3.6.1.2.1.2.2',
      ifEntry => '1.3.6.1.2.1.2.2.1',
      ifIndex => '1.3.6.1.2.1.2.2.1.1',
      ifDescr => '1.3.6.1.2.1.2.2.1.2',
      ifType => '1.3.6.1.2.1.2.2.1.3',
      ifTypeDefinition => 'IFMIB::ifType',
      ifMtu => '1.3.6.1.2.1.2.2.1.4',
      ifSpeed => '1.3.6.1.2.1.2.2.1.5',
      ifPhysAddress => '1.3.6.1.2.1.2.2.1.6',
      ifAdminStatus => '1.3.6.1.2.1.2.2.1.7',
      ifOperStatus => '1.3.6.1.2.1.2.2.1.8',
      ifLastChange => '1.3.6.1.2.1.2.2.1.9',
      ifInOctets => '1.3.6.1.2.1.2.2.1.10',
      ifInUcastPkts => '1.3.6.1.2.1.2.2.1.11',
      ifInNUcastPkts => '1.3.6.1.2.1.2.2.1.12',
      ifInDiscards => '1.3.6.1.2.1.2.2.1.13',
      ifInErrors => '1.3.6.1.2.1.2.2.1.14',
      ifInUnknownProtos => '1.3.6.1.2.1.2.2.1.15',
      ifOutOctets => '1.3.6.1.2.1.2.2.1.16',
      ifOutUcastPkts => '1.3.6.1.2.1.2.2.1.17',
      ifOutNUcastPkts => '1.3.6.1.2.1.2.2.1.18',
      ifOutDiscards => '1.3.6.1.2.1.2.2.1.19',
      ifOutErrors => '1.3.6.1.2.1.2.2.1.20',
      ifOutQLen => '1.3.6.1.2.1.2.2.1.21',
      ifSpecific => '1.3.6.1.2.1.2.2.1.22',
      ifAdminStatusDefinition => {
          1 => 'up',
          2 => 'down',
          3 => 'testing',
      },
      ifOperStatusDefinition => {
          1 => 'up',
          2 => 'down',
          3 => 'testing',
          4 => 'unknown',
          5 => 'dormant',
          6 => 'notPresent',
          7 => 'lowerLayerDown',
      },
      # INDEX { ifIndex }
      #
      ifXTable => '1.3.6.1.2.1.31.1.1',
      ifXEntry => '1.3.6.1.2.1.31.1.1.1',
      ifName => '1.3.6.1.2.1.31.1.1.1.1',
      ifInMulticastPkts => '1.3.6.1.2.1.31.1.1.1.2',
      ifInBroadcastPkts => '1.3.6.1.2.1.31.1.1.1.3',
      ifOutMulticastPkts => '1.3.6.1.2.1.31.1.1.1.4',
      ifOutBroadcastPkts => '1.3.6.1.2.1.31.1.1.1.5',
      ifHCInOctets => '1.3.6.1.2.1.31.1.1.1.6',
      ifHCInUcastPkts => '1.3.6.1.2.1.31.1.1.1.7',
      ifHCInMulticastPkts => '1.3.6.1.2.1.31.1.1.1.8',
      ifHCInBroadcastPkts => '1.3.6.1.2.1.31.1.1.1.9',
      ifHCOutOctets => '1.3.6.1.2.1.31.1.1.1.10',
      ifHCOutUcastPkts => '1.3.6.1.2.1.31.1.1.1.11',
      ifHCOutMulticastPkts => '1.3.6.1.2.1.31.1.1.1.12',
      ifHCOutBroadcastPkts => '1.3.6.1.2.1.31.1.1.1.13',
      ifLinkUpDownTrapEnable => '1.3.6.1.2.1.31.1.1.1.14',
      ifHighSpeed => '1.3.6.1.2.1.31.1.1.1.15',
      ifPromiscuousMode => '1.3.6.1.2.1.31.1.1.1.16',
      ifConnectorPresent => '1.3.6.1.2.1.31.1.1.1.17',
      ifAlias => '1.3.6.1.2.1.31.1.1.1.18',
      ifCounterDiscontinuityTime => '1.3.6.1.2.1.31.1.1.1.19',
      ifLinkUpDownTrapEnableDefinition => {
          1 => 'enabled',
          2 => 'disabled',
      },
      # ifXEntry AUGMENTS ifEntry
      #
  },
  'UPSV4-MIB' => {
      delta => '1.3.6.1.4.1.2254',
      ups => '1.3.6.1.4.1.2254.2',
      upsv4 => '1.3.6.1.4.1.2254.2.4',
    dupsIdent => '1.3.6.1.4.1.2254.2.4.1',
    dupsIdentManufacturer => '1.3.6.1.4.1.2254.2.4.1.1',
    dupsRatingInputVoltage => '1.3.6.1.4.1.2254.2.4.1.10',
    dupsRatingInputFrequency => '1.3.6.1.4.1.2254.2.4.1.11',
    dupsRatingBatteryVoltage => '1.3.6.1.4.1.2254.2.4.1.12',
    dupsLowTransferVoltUpBound => '1.3.6.1.4.1.2254.2.4.1.13',
    dupsLowTransferVoltLowBound => '1.3.6.1.4.1.2254.2.4.1.14',
    dupsHighTransferVoltUpBound => '1.3.6.1.4.1.2254.2.4.1.15',
    dupsHighTransferVoltLowBound => '1.3.6.1.4.1.2254.2.4.1.16',
    dupsLowBattTime => '1.3.6.1.4.1.2254.2.4.1.17',
    dupsOutletRelays => '1.3.6.1.4.1.2254.2.4.1.18',
    dupsType => '1.3.6.1.4.1.2254.2.4.1.19',
    dupsTypeDefinition => {
      1 => 'on-line',
      2 => 'off-line',
      3 => 'line-interactive',
      4 => '3phase',
      5 => 'splite-phase',
    },
    dupsIdentModel => '1.3.6.1.4.1.2254.2.4.1.2',
    dupsIdentUPSSoftwareVersion => '1.3.6.1.4.1.2254.2.4.1.3',
    dupsIdentAgentSoftwareVersion => '1.3.6.1.4.1.2254.2.4.1.4',
    dupsIdentName => '1.3.6.1.4.1.2254.2.4.1.5',
    dupsAttachedDevices => '1.3.6.1.4.1.2254.2.4.1.6',
    dupsRatingOutputVA => '1.3.6.1.4.1.2254.2.4.1.7',
    dupsRatingOutputVoltage => '1.3.6.1.4.1.2254.2.4.1.8',
    dupsRatingOutputFrequency => '1.3.6.1.4.1.2254.2.4.1.9',
    dupsEnvironment => '1.3.6.1.4.1.2254.2.4.10',
    dupsEnvTemperature => '1.3.6.1.4.1.2254.2.4.10.1',
    dupsAlarmOverEnvHumidity => '1.3.6.1.4.1.2254.2.4.10.10',
    dupsAlarmOverEnvHumidityDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmEnvRelay1 => '1.3.6.1.4.1.2254.2.4.10.11',
    dupsAlarmEnvRelay1Definition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmEnvRelay2 => '1.3.6.1.4.1.2254.2.4.10.12',
    dupsAlarmEnvRelay2Definition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmEnvRelay3 => '1.3.6.1.4.1.2254.2.4.10.13',
    dupsAlarmEnvRelay3Definition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmEnvRelay4 => '1.3.6.1.4.1.2254.2.4.10.14',
    dupsAlarmEnvRelay4Definition => 'DELTAUPS-MIB::dupsAlarm',
    dupsEnvHumidity => '1.3.6.1.4.1.2254.2.4.10.2',
    dupsEnvSetTemperatureLimit => '1.3.6.1.4.1.2254.2.4.10.3',
    dupsEnvSetHumidityLimit => '1.3.6.1.4.1.2254.2.4.10.4',
    dupsEnvSetEnvRelay1 => '1.3.6.1.4.1.2254.2.4.10.5',
    dupsEnvSetEnvRelay2 => '1.3.6.1.4.1.2254.2.4.10.6',
    dupsEnvSetEnvRelay3 => '1.3.6.1.4.1.2254.2.4.10.7',
    dupsEnvSetEnvRelay4 => '1.3.6.1.4.1.2254.2.4.10.8',
    dupsAlarmOverEnvTemperature => '1.3.6.1.4.1.2254.2.4.10.9',
    dupsAlarmOverEnvTemperatureDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsControl => '1.3.6.1.4.1.2254.2.4.2',
    dupsShutdownType => '1.3.6.1.4.1.2254.2.4.2.1',
    dupsAutoReboot => '1.3.6.1.4.1.2254.2.4.2.2',
    dupsShutdownAction => '1.3.6.1.4.1.2254.2.4.2.3',
    dupsShutdownRestart => '1.3.6.1.4.1.2254.2.4.2.4',
    dupsSetOutletRelay => '1.3.6.1.4.1.2254.2.4.2.5',
    dupsRelayOffDelay => '1.3.6.1.4.1.2254.2.4.2.6',
    dupsRelayOnDelay => '1.3.6.1.4.1.2254.2.4.2.7',
    dupsConfig => '1.3.6.1.4.1.2254.2.4.3',
    dupsConfigBuzzerAlarm => '1.3.6.1.4.1.2254.2.4.3.1',
    dupsConfigBuzzerState => '1.3.6.1.4.1.2254.2.4.3.2',
    dupsConfigSensitivity => '1.3.6.1.4.1.2254.2.4.3.3',
    dupsConfigLowVoltageTransferPoint => '1.3.6.1.4.1.2254.2.4.3.4',
    dupsConfigHighVoltageTransferPoint => '1.3.6.1.4.1.2254.2.4.3.5',
    dupsConfigShutdownOSDelay => '1.3.6.1.4.1.2254.2.4.3.6',
    dupsConfigUPSBootDelay => '1.3.6.1.4.1.2254.2.4.3.7',
    dupsConfigExternalBatteryPack => '1.3.6.1.4.1.2254.2.4.3.8',
    dupsInput => '1.3.6.1.4.1.2254.2.4.4',
    dupsInputNumLines => '1.3.6.1.4.1.2254.2.4.4.1',
    dupsInputCurrent3 => '1.3.6.1.4.1.2254.2.4.4.10',
    dupsInputFrequency1 => '1.3.6.1.4.1.2254.2.4.4.2',
    dupsInputVoltage1 => '1.3.6.1.4.1.2254.2.4.4.3',
    dupsInputCurrent1 => '1.3.6.1.4.1.2254.2.4.4.4',
    dupsInputFrequency2 => '1.3.6.1.4.1.2254.2.4.4.5',
    dupsInputVoltage2 => '1.3.6.1.4.1.2254.2.4.4.6',
    dupsInputCurrent2 => '1.3.6.1.4.1.2254.2.4.4.7',
    dupsInputFrequency3 => '1.3.6.1.4.1.2254.2.4.4.8',
    dupsInputVoltage3 => '1.3.6.1.4.1.2254.2.4.4.9',
    dupsOutput => '1.3.6.1.4.1.2254.2.4.5',
    dupsOutputSource => '1.3.6.1.4.1.2254.2.4.5.1',
    dupsOutputSourceDefinition => {
      0 => 'normal',
      1 => 'battery',
      2 => 'bypass',
      3 => 'reducing',
      4 => 'boosting',
      5 => 'manualBypass',
      6 => 'other',
      7 => 'none',
    },
    dupsOutputPower2 => '1.3.6.1.4.1.2254.2.4.5.10',
    dupsOutputLoad2 => '1.3.6.1.4.1.2254.2.4.5.11',
    dupsOutputVoltage3 => '1.3.6.1.4.1.2254.2.4.5.12',
    dupsOutputCurrent3 => '1.3.6.1.4.1.2254.2.4.5.13',
    dupsOutputPower3 => '1.3.6.1.4.1.2254.2.4.5.14',
    dupsOutputLoad3 => '1.3.6.1.4.1.2254.2.4.5.15',
    dupsOutputFrequency => '1.3.6.1.4.1.2254.2.4.5.2',
    dupsOutputNumLines => '1.3.6.1.4.1.2254.2.4.5.3',
    dupsOutputVoltage1 => '1.3.6.1.4.1.2254.2.4.5.4',
    dupsOutputCurrent1 => '1.3.6.1.4.1.2254.2.4.5.5',
    dupsOutputPower1 => '1.3.6.1.4.1.2254.2.4.5.6',
    dupsOutputLoad1 => '1.3.6.1.4.1.2254.2.4.5.7',
    dupsOutputVoltage2 => '1.3.6.1.4.1.2254.2.4.5.8',
    dupsOutputCurrent2 => '1.3.6.1.4.1.2254.2.4.5.9',
    dupsBypass => '1.3.6.1.4.1.2254.2.4.6',
    dupsBypassFrequency => '1.3.6.1.4.1.2254.2.4.6.1',
    dupsBypassCurrent3 => '1.3.6.1.4.1.2254.2.4.6.10',
    dupsBypassPower3 => '1.3.6.1.4.1.2254.2.4.6.11',
    dupsBypassNumLines => '1.3.6.1.4.1.2254.2.4.6.2',
    dupsBypassVoltage1 => '1.3.6.1.4.1.2254.2.4.6.3',
    dupsBypassCurrent1 => '1.3.6.1.4.1.2254.2.4.6.4',
    dupsBypassPower1 => '1.3.6.1.4.1.2254.2.4.6.5',
    dupsBypassVoltage2 => '1.3.6.1.4.1.2254.2.4.6.6',
    dupsBypassCurrent2 => '1.3.6.1.4.1.2254.2.4.6.7',
    dupsBypassPower2 => '1.3.6.1.4.1.2254.2.4.6.8',
    dupsBypassVoltage3 => '1.3.6.1.4.1.2254.2.4.6.9',
    dupsBattery => '1.3.6.1.4.1.2254.2.4.7',
    dupsBatteryCondiction => '1.3.6.1.4.1.2254.2.4.7.1',
    dupsBatteryCondictionDefinition => {
      0 => 'good',
      1 => 'weak',
      2 => 'replace',
    },
    dupsLastReplaceDate => '1.3.6.1.4.1.2254.2.4.7.10',
    dupsNextReplaceDate => '1.3.6.1.4.1.2254.2.4.7.11',
    dupsBatteryStatus => '1.3.6.1.4.1.2254.2.4.7.2',
    dupsBatteryStatusDefinition => {
      0 => 'ok',
      1 => 'low',
      2 => 'depleted',
    },
    dupsBatteryCharge => '1.3.6.1.4.1.2254.2.4.7.3',
    dupsBatteryChargeDefinition => {
      0 => 'floating',
      1 => 'charging',
      2 => 'resting',
      3 => 'discharging',
    },
    dupsSecondsOnBattery => '1.3.6.1.4.1.2254.2.4.7.4',
    dupsBatteryEstimatedTime => '1.3.6.1.4.1.2254.2.4.7.5',
    dupsBatteryVoltage => '1.3.6.1.4.1.2254.2.4.7.6',
    dupsBatteryCurrent => '1.3.6.1.4.1.2254.2.4.7.7',
    dupsBatteryCapacity => '1.3.6.1.4.1.2254.2.4.7.8',
    dupsTemperature => '1.3.6.1.4.1.2254.2.4.7.9',
    dupsTest => '1.3.6.1.4.1.2254.2.4.8',
    dupsTestType => '1.3.6.1.4.1.2254.2.4.8.1',
    dupsTestTypeDefinition => {
      0 => 'abort',
      1 => 'generalTest',
      2 => 'batteryTest',
      3 => 'testFor10sec',
      4 => 'testUntilBattlow',
    },
    dupsTestResultsSummary => '1.3.6.1.4.1.2254.2.4.8.2',
    dupsTestResultsSummaryDefinition => {
      0 => 'noTestsInitiated',
      1 => 'donePass',
      2 => 'inProgress',
      3 => 'generalTestFail',
      4 => 'batteryTestFail',
      5 => 'deepBatteryTestFail',
    },
    dupsTestResultsDetail => '1.3.6.1.4.1.2254.2.4.8.3',

    dupsAlarm => '1.3.6.1.4.1.2254.2.4.9',
    dupsAlarmDisconnect => '1.3.6.1.4.1.2254.2.4.9.1',
    dupsAlarmBatteryTestFail => '1.3.6.1.4.1.2254.2.4.9.10',
    dupsAlarmFuseFailure => '1.3.6.1.4.1.2254.2.4.9.11',
    dupsAlarmOutputOverload => '1.3.6.1.4.1.2254.2.4.9.12',
    dupsAlarmOutputOverCurrent => '1.3.6.1.4.1.2254.2.4.9.13',
    dupsAlarmInverterAbnormal => '1.3.6.1.4.1.2254.2.4.9.14',
    dupsAlarmRectifierAbnormal => '1.3.6.1.4.1.2254.2.4.9.15',
    dupsAlarmReserveAbnormal => '1.3.6.1.4.1.2254.2.4.9.16',
    dupsAlarmLoadOnReserve => '1.3.6.1.4.1.2254.2.4.9.17',
    dupsAlarmOverTemperature => '1.3.6.1.4.1.2254.2.4.9.18',
    dupsAlarmOutputBad => '1.3.6.1.4.1.2254.2.4.9.19',
    dupsAlarmPowerFail => '1.3.6.1.4.1.2254.2.4.9.2',
    dupsAlarmBypassBad => '1.3.6.1.4.1.2254.2.4.9.20',
    dupsAlarmUPSOff => '1.3.6.1.4.1.2254.2.4.9.21',
    dupsAlarmChargerFail => '1.3.6.1.4.1.2254.2.4.9.22',
    dupsAlarmFanFail => '1.3.6.1.4.1.2254.2.4.9.23',
    dupsAlarmEconomicMode => '1.3.6.1.4.1.2254.2.4.9.24',
    dupsAlarmOutputOff => '1.3.6.1.4.1.2254.2.4.9.25',
    dupsAlarmSmartShutdown => '1.3.6.1.4.1.2254.2.4.9.26',
    dupsAlarmEmergencyPowerOff => '1.3.6.1.4.1.2254.2.4.9.27',
    dupsAlarmBatteryLow => '1.3.6.1.4.1.2254.2.4.9.3',
    dupsAlarmLoadWarning => '1.3.6.1.4.1.2254.2.4.9.4',
    dupsAlarmLoadSeverity => '1.3.6.1.4.1.2254.2.4.9.5',
    dupsAlarmLoadOnBypass => '1.3.6.1.4.1.2254.2.4.9.6',
    dupsAlarmUPSFault => '1.3.6.1.4.1.2254.2.4.9.7',
    dupsAlarmBatteryGroundFault => '1.3.6.1.4.1.2254.2.4.9.8',
    dupsAlarmTestInProgress => '1.3.6.1.4.1.2254.2.4.9.9',
    dupsAlarmDisconnectDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmBatteryTestFailDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmFuseFailureDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmOutputOverloadDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmOutputOverCurrentDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmInverterAbnormalDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmRectifierAbnormalDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmReserveAbnormalDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmLoadOnReserveDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmOverTemperatureDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmOutputBadDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmPowerFailDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmBypassBadDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmUPSOffDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmChargerFailDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmFanFailDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmEconomicModeDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmOutputOffDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmSmartShutdownDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmEmergencyPowerOffDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmBatteryLowDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmLoadWarningDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmLoadSeverityDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmLoadOnBypassDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmUPSFaultDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmBatteryGroundFaultDefinition => 'DELTAUPS-MIB::dupsAlarm',
    dupsAlarmTestInProgressDefinition => 'DELTAUPS-MIB::dupsAlarm',
  },
  'MG-SNMP-UPS-MIB' => {
  },
};

$UPS::Device::definitions = {
  'DELTAUPS-MIB' => {
     dupsAlarm => {
       0 => 'off',
       1 => 'on',
     },
     dupsRelay => {
       0 => 'normalOpen',
       1 => 'normalClose',
     },
  },
};

