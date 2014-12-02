package MyRaritan;
our @ISA = qw(GLPlugin::SNMP);

sub init {
  my $self = shift;
  $GLPlugin::SNMP::mibs_and_oids->{'PDU2-MIB'} =
      $MyRaritan::mibs_and_oids->{'PDU2-MIB'};
  $GLPlugin::SNMP::definitions->{'PDU2-MIB'} =
      $MyRaritan::definitions->{'PDU2-MIB'};
  #if ($self->mode =~ /device::hardware::health/) {
printf "%s\n", $self->mode;
  if ($self->mode =~ /my::raritan::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem('Classes::Raritan::Components::ExternalSensorSubsystem');
    if (! $self->check_messages()) {
      $self->add_ok('hardware working fine');
    }
  } elsif ($self->mode =~ /my::raritan::battery::health/) {
    $self->analyze_and_check_environmental_subsystem('Classes::Raritan::Components::InletSensorSubsystem');
    if (! $self->check_messages()) {
      $self->add_ok('hardware working fine');
    }
  } elsif ($self->mode =~ /device::hardware::load/) {
  } elsif ($self->mode =~ /device::hardware::memory/) {
  } else {
    $self->no_such_mode();
  }
}
# 

package Classes::Raritan::Components::ExternalSensorSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('PDU2-MIB', [
    ['extsensconfigs', 'externalSensorConfigurationTable', 'Classes::Raritan::Components::EnvironmentalSubsystem::ExternalSensor'],
    ['extsensmeasurements', 'externalSensorMeasurementsTable', 'Classes::Raritan::Components::EnvironmentalSubsystem::ExternalSensorMeasurement'],
  ]);
  foreach my $extmeasure (@{$self->{extsensmeasurements}}) {
    # pduId, sensorID
    foreach my $extconfig (@{$self->{extsensconfigs}}) {
      # pduId, sensorID
      if ($extmeasure->{flat_indices} eq $extconfig->{flat_indices}) {
        foreach (grep /measurements/, keys %{$extmeasure}) {
          $extconfig->{$_} = $extmeasure->{$_};
        }
        $extconfig->shorten();
      }
    }
  }
}

sub check {
  my $self = shift;
  foreach (@{$self->{extsensconfigs}}) {
    $_->check();
  }
}

package Classes::Raritan::Components::InletSensorSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('PDU2-MIB', [
    ['inlsensconfigs', 'inletSensorConfigurationTable', 'Classes::Raritan::Components::EnvironmentalSubsystem::InletSensor'],
    ['inlsensmeasurements', 'inletSensorMeasurementsTable', 'Classes::Raritan::Components::EnvironmentalSubsystem::InletSensorMeasurement'],
  ]);
  foreach my $inlmeasure (@{$self->{inlsensmeasurements}}) {
    # pduId, sensorID
    foreach my $inlconfig (@{$self->{inlsensconfigs}}) {
      # pduId, sensorID
      if ($inlmeasure->{flat_indices} eq $inlconfig->{flat_indices}) {
        foreach (grep /measurements/, keys %{$inlmeasure}) {
          $inlconfig->{$_} = $inlmeasure->{$_};
        }
        $inlconfig->shorten();
      }
    }
  }
}

sub check {
  my $self = shift;
  foreach (@{$self->{inlsensconfigs}}) {
    $_->check();
  }
}


package Classes::Raritan::Components::EnvironmentalSubsystem::ThresholdEnabledSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem Classes::Raritan::Components::EnvironmentalSubsystem::Sensor);

sub check {
  my $self = shift;
  if ($self->{SensorIsAvailable} eq 'true') {
    $self->add_info(sprintf '%s sensor %s is %s',
        $self->{SensorType}, $self->{SensorName}, $self->{SensorState});
    $self->add_info(sprintf '%s sensor %s shows %s%s',
        $self->{SensorType}, $self->{SensorName},
        $self->{SensorValue}, $self->{SensorUnits});
    $self->make_thresholds();
    my $level = $self->check_thresholds(
        metric => 'sensor_'.$self->{SensorName},
        value => $self->{SensorValue},
    );
    if ($level || $self->{SensorState} =~ /(below|above)/) {
      $self->add_message($level, sprintf '%s is out of range (%s%s)',
          $self->{SensorName}, $self->{SensorValue}, 
          $self->{SensorUnits});
    } else {
      $self->add_ok();
    }
    $self->add_perfdata(label => 'sensor_'.$self->{SensorName},
        value => $self->{SensorValue},
        thresholds => 1,
        units => $self->{SensorUnits} eq '%' ? '%' : undef,
    );
  }
}

sub make_thresholds {
  my $self = shift;
  # 0 => 'lowerCritical', 1 => 'lowerWarning', 2 => 'upperWarning', 3 => 'upperCritical',
  my $EnabledThresholds = $self->{SensorEnabledThresholds};
  if ($EnabledThresholds =~ /^0x(\w)0/) {
    $EnabledThresholds = hex $1;
  } elsif ($EnabledThresholds =~ /^(\w)0/) {
    $EnabledThresholds = hex $1;
  } else {
    $EnabledThresholds = hex unpack('H1', $EnabledThresholds);
  }
  #$EnabledThresholds >>= 8;
  $EnabledThresholds &= 0xf;
  # 0000 nix w
  # 0010 lw
  # 0100 uw
  # 0110 luw
  $self->{warning} = undef;
  if ($EnabledThresholds & 0x1a == 0x1a) {
    $self->{warning} = sprintf "%.2f:%.2f",
        $self->{SensorLowerWarningThreshold},
        $self->{SensorUpperWarningThreshold};
  } elsif ($EnabledThresholds & 0x10 == 0x10) {
    $self->{warning} = sprintf "%.2f",
        $self->{SensorUpperWarningThreshold};
  } elsif ($EnabledThresholds & 0x0a == 0x0a) {
    $self->{warning} = sprintf "%.2f:",
        $self->{SensorLowerWarningThreshold};
  }
  # 1000 uc
  # 0001 lc
  # 1001 ulc
  $self->{critical} = undef;
  if ($EnabledThresholds & 0xa1 == 0xa1) {
    $self->{critical} = sprintf "%.2f:%.2f",
        $self->{SensorLowerCriticalThreshold},
        $self->{SensorUpperCriticalThreshold};
  } elsif ($EnabledThresholds & 0xa0 == 0xa0) {
    $self->{critical} = sprintf "%.2f",
        $self->{SensorUpperCriticalThreshold};
  } elsif ($EnabledThresholds & 0x01 == 0x01) {
    $self->{critical} = sprintf "%.2f:",
        $self->{SensorLowerCriticalThreshold};
  }
  $self->set_thresholds(metric => 'sensor_'.$self->{SensorName},
      warning => $self->{warning}, critical => $self->{critical});
}

package Classes::Raritan::Components::EnvironmentalSubsystem::Sensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  if ($self->{SensorIsAvailable} eq 'true') {
    if (defined $self->{SensorValue} =~ /^\d+$/) {
      $self->add_info(sprintf '%s sensor %s is %s (%.2f %s)',
          $self->{SensorType}, $self->{SensorName}, $self->{SensorState},
          $self->{SensorValue}, $self->{SensorUnits});
      $self->add_perfdata(label => 'sensor_'.$self->{SensorName},
          value => $self->{SensorValue},
          thresholds => 0,
          units => $self->{SensorUnits} eq '%' ? '%' : undef,
      );
    } else {
      $self->add_info(sprintf '%s sensor %s is %s',
          $self->{SensorType}, $self->{SensorName}, $self->{SensorState});
    }
    if (grep { $self->{SensorState} eq $_ } qw(normal closed on ok inSync)) {
    } else {
      $self->add_critical();
    }
  }
}

sub shorten {
  my $self = shift;
  foreach (keys %{$self}) {
    if ($_ =~ /^measurements(\w+)Sensor(.*)/) {
      $self->{'Sensor'.$2} = $self->{$_};
      delete $self->{$_};
    } elsif ($_ =~ /^(\w+)Sensor(.*)/) {
      $self->{'Sensor'.$2} = $self->{$_};
      delete $self->{$_};
    }
  }
  foreach (qw(SensorValue SensorLowerWarningThreshold
      SensorLowerCriticalThreshold SensorUpperWarningThreshold
      SensorUpperCriticalThreshold)) {
    if ($self->{$_} =~ /^[\d\.]+$/ &&
        $self->{SensorDecimalDigits} =~ /^[\d\.]+$/) {
      $self->{$_} /=
          10 ** $self->{SensorDecimalDigits};
    }
  }
}

package Classes::Raritan::Components::EnvironmentalSubsystem::ExternalSensorMeasurement;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::ExternalSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem Classes::Raritan::Components::EnvironmentalSubsystem::Sensor);
use strict;

sub finish {
  my $self = shift;
  if ($self->{externalSensorType} eq 'temperature') {
    bless $self, 'Classes::Raritan::Components::EnvironmentalSubsystem::TemperatureSensor';
    $self->finish2();
  } elsif ($self->{externalSensorType} eq 'humidity') {
    bless $self, 'Classes::Raritan::Components::EnvironmentalSubsystem::HumiditySensor';
    $self->finish2();
  }
}

package Classes::Raritan::Components::EnvironmentalSubsystem::InternalSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::RmsCurrentSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::PeakCurrentSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::UnbalancedCurrentSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::RmsVoltageSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::ActivePowerSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::ApparentPowerSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::PowerFactorSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::ActiveEnergySensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::ApparentEnergySensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::TemperatureSensor;
our @ISA = qw(Classes::Raritan::Components::EnvironmentalSubsystem::ThresholdEnabledSensor GLPlugin::SNMP::TableItem);
use strict;

sub finish2 {
  my $self = shift;
  $self->{externalSensorUnits} = 'C' if $self->{externalSensorUnits} eq 'degreeC';
  $self->{externalSensorUnits} = 'F' if $self->{externalSensorUnits} eq 'degreeF';
  $self->{externalSensorUnits} = '' if $self->{externalSensorUnits} eq 'degrees';
}

package Classes::Raritan::Components::EnvironmentalSubsystem::HumiditySensor;
our @ISA = qw(Classes::Raritan::Components::EnvironmentalSubsystem::ThresholdEnabledSensor GLPlugin::SNMP::TableItem);
use strict;

sub finish2 {
  my $self = shift;
  $self->{externalSensorUnits} = '%';
}

package Classes::Raritan::Components::EnvironmentalSubsystem::AirFlowSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::AirPressureSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::OnOffSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::TripSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::VibrationSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::WaterDetectionSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::SmokeDetectionSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::BinarySensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::ContactSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::FanSpeedSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::SurgeProtectorStatusSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::FrequencySensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::PhaseAngleSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::OtherSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::NoneSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::PowerQualitySensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::OverloadStatusSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::OverheatStatusSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::ScrOpenStatusSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::ScrShortStatusSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::FanStatusSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::InletPhaseSyncAngleSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::InletPhaseSyncSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::OperatingStateSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::ActiveInletSensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

package Classes::Raritan::Components::EnvironmentalSubsystem::InletSensor;
our @ISA = qw(Classes::Raritan::Components::EnvironmentalSubsystem::Sensor GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my $self = shift;
  $self->{inletSensorType} = 'inlet';
  $self->{inletSensorName} = $self->{flat_indices};
}

package Classes::Raritan::Components::EnvironmentalSubsystem::InletSensorMeasurement;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;


$MyRaritan::mibs_and_oids = {
  'PDU2-MIB' => {
    raritan => '1.3.6.1.4.1.13742',
    pdu2 => '1.3.6.1.4.1.13742.6',
    traps => '1.3.6.1.4.1.13742.6.0',
    trapInformation => '1.3.6.1.4.1.13742.6.0.0',
    trapInformationTable => '1.3.6.1.4.1.13742.6.0.0.1',
    trapInformationEntry => '1.3.6.1.4.1.13742.6.0.0.1.1',
    userName => '1.3.6.1.4.1.13742.6.0.0.1.1.2',
    targetUser => '1.3.6.1.4.1.13742.6.0.0.1.1.3',
    imageVersion => '1.3.6.1.4.1.13742.6.0.0.1.1.5',
    roleName => '1.3.6.1.4.1.13742.6.0.0.1.1.6',
    smtpMessageRecipients => '1.3.6.1.4.1.13742.6.0.0.1.1.7',
    smtpServer => '1.3.6.1.4.1.13742.6.0.0.1.1.8',
    oldSensorState => '1.3.6.1.4.1.13742.6.0.0.2',
    pduNumber => '1.3.6.1.4.1.13742.6.0.0.3',
    inletPoleNumber => '1.3.6.1.4.1.13742.6.0.0.5',
    outletPoleNumber => '1.3.6.1.4.1.13742.6.0.0.7',
    externalSensorNumber => '1.3.6.1.4.1.13742.6.0.0.8',
    typeOfSensor => '1.3.6.1.4.1.13742.6.0.0.10',
    errorDescription => '1.3.6.1.4.1.13742.6.0.0.11',
    deviceChangedParameter => '1.3.6.1.4.1.13742.6.0.0.12',
    changedParameterNewValue => '1.3.6.1.4.1.13742.6.0.0.13',
    lhxSupportEnabled => '1.3.6.1.4.1.13742.6.0.0.14',
    board => '1.3.6.1.4.1.13742.6.1',
    environmental => '1.3.6.1.4.1.13742.6.2',
    configuration => '1.3.6.1.4.1.13742.6.3',
    pduCount => '1.3.6.1.4.1.13742.6.3.1',
    unit => '1.3.6.1.4.1.13742.6.3.2',
    nameplateTable => '1.3.6.1.4.1.13742.6.3.2.1',
    nameplateEntry => '1.3.6.1.4.1.13742.6.3.2.1.1',
    pduId => '1.3.6.1.4.1.13742.6.3.2.1.1.1',
    pduManufacturer => '1.3.6.1.4.1.13742.6.3.2.1.1.2',
    pduModel => '1.3.6.1.4.1.13742.6.3.2.1.1.3',
    pduSerialNumber => '1.3.6.1.4.1.13742.6.3.2.1.1.4',
    pduRatedVoltage => '1.3.6.1.4.1.13742.6.3.2.1.1.5',
    pduRatedCurrent => '1.3.6.1.4.1.13742.6.3.2.1.1.6',
    pduRatedFrequency => '1.3.6.1.4.1.13742.6.3.2.1.1.7',
    pduRatedVA => '1.3.6.1.4.1.13742.6.3.2.1.1.8',
    pduImage => '1.3.6.1.4.1.13742.6.3.2.1.1.9',
    unitConfigurationTable => '1.3.6.1.4.1.13742.6.3.2.2',
    unitConfigurationEntry => '1.3.6.1.4.1.13742.6.3.2.2.1',
    inletCount => '1.3.6.1.4.1.13742.6.3.2.2.1.2',
    overCurrentProtectorCount => '1.3.6.1.4.1.13742.6.3.2.2.1.3',
    outletCount => '1.3.6.1.4.1.13742.6.3.2.2.1.4',
    inletControllerCount => '1.3.6.1.4.1.13742.6.3.2.2.1.5',
    outletControllerCount => '1.3.6.1.4.1.13742.6.3.2.2.1.6',
    externalSensorCount => '1.3.6.1.4.1.13742.6.3.2.2.1.7',
    pxIPAddress => '1.3.6.1.4.1.13742.6.3.2.2.1.8',
    netmask => '1.3.6.1.4.1.13742.6.3.2.2.1.9',
    gateway => '1.3.6.1.4.1.13742.6.3.2.2.1.10',
    pxMACAddress => '1.3.6.1.4.1.13742.6.3.2.2.1.11',
    utcOffset => '1.3.6.1.4.1.13742.6.3.2.2.1.12',
    pduName => '1.3.6.1.4.1.13742.6.3.2.2.1.13',
    externalSensorsZCoordinateUnits => '1.3.6.1.4.1.13742.6.3.2.2.1.34',
    unitDeviceCapabilities => '1.3.6.1.4.1.13742.6.3.2.2.1.35',
    outletSequencingDelay => '1.3.6.1.4.1.13742.6.3.2.2.1.36',
    globalOutletPowerCyclingPowerOffPeriod => '1.3.6.1.4.1.13742.6.3.2.2.1.37',
    globalOutletStateOnStartup => '1.3.6.1.4.1.13742.6.3.2.2.1.38',
    outletPowerupSequence => '1.3.6.1.4.1.13742.6.3.2.2.1.39',
    pduPowerCyclingPowerOffPeriod => '1.3.6.1.4.1.13742.6.3.2.2.1.40',
    pduDaisychainMemberType => '1.3.6.1.4.1.13742.6.3.2.2.1.41',
    managedExternalSensorCount => '1.3.6.1.4.1.13742.6.3.2.2.1.42',
    pxInetAddressType => '1.3.6.1.4.1.13742.6.3.2.2.1.50',
    pxInetIPAddress => '1.3.6.1.4.1.13742.6.3.2.2.1.51',
    pxInetNetmask => '1.3.6.1.4.1.13742.6.3.2.2.1.52',
    pxInetGateway => '1.3.6.1.4.1.13742.6.3.2.2.1.53',
    loadShedding => '1.3.6.1.4.1.13742.6.3.2.2.1.55',
    serverCount => '1.3.6.1.4.1.13742.6.3.2.2.1.56',
    inrushGuardDelay => '1.3.6.1.4.1.13742.6.3.2.2.1.57',
    cascadedDeviceConnected => '1.3.6.1.4.1.13742.6.3.2.2.1.58',
    synchronizeWithNTPServer => '1.3.6.1.4.1.13742.6.3.2.2.1.59',
    useDHCPProvidedNTPServer => '1.3.6.1.4.1.13742.6.3.2.2.1.60',
    firstNTPServerAddressType => '1.3.6.1.4.1.13742.6.3.2.2.1.61',
    firstNTPServerAddress => '1.3.6.1.4.1.13742.6.3.2.2.1.62',
    secondNTPServerAddressType => '1.3.6.1.4.1.13742.6.3.2.2.1.63',
    secondNTPServerAddress => '1.3.6.1.4.1.13742.6.3.2.2.1.64',
    wireCount => '1.3.6.1.4.1.13742.6.3.2.2.1.65',
    transferSwitchCount => '1.3.6.1.4.1.13742.6.3.2.2.1.66',
    controllerConfigurationTable => '1.3.6.1.4.1.13742.6.3.2.3',
    controllerConfigurationEntry => '1.3.6.1.4.1.13742.6.3.2.3.1',
    boardType => '1.3.6.1.4.1.13742.6.3.2.3.1.1',
    boardIndex => '1.3.6.1.4.1.13742.6.3.2.3.1.2',
    boardVersion => '1.3.6.1.4.1.13742.6.3.2.3.1.4',
    boardFirmwareVersion => '1.3.6.1.4.1.13742.6.3.2.3.1.6',
    boardFirmwareTimeStamp => '1.3.6.1.4.1.13742.6.3.2.3.1.8',
    logConfigurationTable => '1.3.6.1.4.1.13742.6.3.2.4',
    logConfigurationEntry => '1.3.6.1.4.1.13742.6.3.2.4.1',
    dataLogging => '1.3.6.1.4.1.13742.6.3.2.4.1.1',
    measurementPeriod => '1.3.6.1.4.1.13742.6.3.2.4.1.2',
    measurementsPerLogEntry => '1.3.6.1.4.1.13742.6.3.2.4.1.3',
    logSize => '1.3.6.1.4.1.13742.6.3.2.4.1.4',
    dataLoggingEnableForAllSensors => '1.3.6.1.4.1.13742.6.3.2.4.1.5',
    unitSensorConfigurationTable => '1.3.6.1.4.1.13742.6.3.2.5',
    unitSensorConfigurationEntry => '1.3.6.1.4.1.13742.6.3.2.5.1',
    sensorType => '1.3.6.1.4.1.13742.6.3.2.5.1.1',
    unitSensorLogAvailable => '1.3.6.1.4.1.13742.6.3.2.5.1.4',
    unitSensorUnits => '1.3.6.1.4.1.13742.6.3.2.5.1.6',
    unitSensorDecimalDigits => '1.3.6.1.4.1.13742.6.3.2.5.1.7',
    unitSensorAccuracy => '1.3.6.1.4.1.13742.6.3.2.5.1.8',
    unitSensorResolution => '1.3.6.1.4.1.13742.6.3.2.5.1.9',
    unitSensorTolerance => '1.3.6.1.4.1.13742.6.3.2.5.1.10',
    unitSensorMaximum => '1.3.6.1.4.1.13742.6.3.2.5.1.11',
    unitSensorMinimum => '1.3.6.1.4.1.13742.6.3.2.5.1.12',
    unitSensorHysteresis => '1.3.6.1.4.1.13742.6.3.2.5.1.13',
    unitSensorStateChangeDelay => '1.3.6.1.4.1.13742.6.3.2.5.1.14',
    unitSensorLowerCriticalThreshold => '1.3.6.1.4.1.13742.6.3.2.5.1.21',
    unitSensorLowerWarningThreshold => '1.3.6.1.4.1.13742.6.3.2.5.1.22',
    unitSensorUpperCriticalThreshold => '1.3.6.1.4.1.13742.6.3.2.5.1.23',
    unitSensorUpperWarningThreshold => '1.3.6.1.4.1.13742.6.3.2.5.1.24',
    unitSensorEnabledThresholds => '1.3.6.1.4.1.13742.6.3.2.5.1.25',
    inlets => '1.3.6.1.4.1.13742.6.3.3',
    inletConfigurationTable => '1.3.6.1.4.1.13742.6.3.3.3',
    inletConfigurationEntry => '1.3.6.1.4.1.13742.6.3.3.3.1',
    inletId => '1.3.6.1.4.1.13742.6.3.3.3.1.1',
    inletLabel => '1.3.6.1.4.1.13742.6.3.3.3.1.2',
    inletName => '1.3.6.1.4.1.13742.6.3.3.3.1.3',
    inletPlug => '1.3.6.1.4.1.13742.6.3.3.3.1.4',
    inletPoleCount => '1.3.6.1.4.1.13742.6.3.3.3.1.5',
    inletRatedVoltage => '1.3.6.1.4.1.13742.6.3.3.3.1.6',
    inletRatedCurrent => '1.3.6.1.4.1.13742.6.3.3.3.1.7',
    inletRatedFrequency => '1.3.6.1.4.1.13742.6.3.3.3.1.8',
    inletRatedVA => '1.3.6.1.4.1.13742.6.3.3.3.1.9',
    inletDeviceCapabilities => '1.3.6.1.4.1.13742.6.3.3.3.1.10',
    inletPoleCapabilities => '1.3.6.1.4.1.13742.6.3.3.3.1.11',
    inletPlugDescriptor => '1.3.6.1.4.1.13742.6.3.3.3.1.12',
    inletSensorConfigurationTable => '1.3.6.1.4.1.13742.6.3.3.4',
    inletSensorConfigurationEntry => '1.3.6.1.4.1.13742.6.3.3.4.1',
    inletSensorLogAvailable => '1.3.6.1.4.1.13742.6.3.3.4.1.4',
    inletSensorUnits => '1.3.6.1.4.1.13742.6.3.3.4.1.6',
    inletSensorUnitsDefinition => 'PDU2-MIB::SensorUnitsEnumeration',
    inletSensorDecimalDigits => '1.3.6.1.4.1.13742.6.3.3.4.1.7',
    inletSensorAccuracy => '1.3.6.1.4.1.13742.6.3.3.4.1.8',
    inletSensorResolution => '1.3.6.1.4.1.13742.6.3.3.4.1.9',
    inletSensorTolerance => '1.3.6.1.4.1.13742.6.3.3.4.1.10',
    inletSensorMaximum => '1.3.6.1.4.1.13742.6.3.3.4.1.11',
    inletSensorMinimum => '1.3.6.1.4.1.13742.6.3.3.4.1.12',
    inletSensorHysteresis => '1.3.6.1.4.1.13742.6.3.3.4.1.13',
    inletSensorStateChangeDelay => '1.3.6.1.4.1.13742.6.3.3.4.1.14',
    inletSensorLowerCriticalThreshold => '1.3.6.1.4.1.13742.6.3.3.4.1.21',
    inletSensorLowerWarningThreshold => '1.3.6.1.4.1.13742.6.3.3.4.1.22',
    inletSensorUpperCriticalThreshold => '1.3.6.1.4.1.13742.6.3.3.4.1.23',
    inletSensorUpperWarningThreshold => '1.3.6.1.4.1.13742.6.3.3.4.1.24',
    inletSensorEnabledThresholds => '1.3.6.1.4.1.13742.6.3.3.4.1.25',
    inletPoleSensorConfigurationTable => '1.3.6.1.4.1.13742.6.3.3.6',
    inletPoleSensorConfigurationEntry => '1.3.6.1.4.1.13742.6.3.3.6.1',
    inletPoleIndex => '1.3.6.1.4.1.13742.6.3.3.6.1.1',
    inletPoleSensorLogAvailable => '1.3.6.1.4.1.13742.6.3.3.6.1.4',
    inletPoleSensorUnits => '1.3.6.1.4.1.13742.6.3.3.6.1.6',
    inletPoleSensorDecimalDigits => '1.3.6.1.4.1.13742.6.3.3.6.1.7',
    inletPoleSensorAccuracy => '1.3.6.1.4.1.13742.6.3.3.6.1.8',
    inletPoleSensorResolution => '1.3.6.1.4.1.13742.6.3.3.6.1.9',
    inletPoleSensorTolerance => '1.3.6.1.4.1.13742.6.3.3.6.1.10',
    inletPoleSensorMaximum => '1.3.6.1.4.1.13742.6.3.3.6.1.11',
    inletPoleSensorMinimum => '1.3.6.1.4.1.13742.6.3.3.6.1.12',
    inletPoleSensorHysteresis => '1.3.6.1.4.1.13742.6.3.3.6.1.13',
    inletPoleSensorStateChangeDelay => '1.3.6.1.4.1.13742.6.3.3.6.1.14',
    inletPoleSensorLowerCriticalThreshold => '1.3.6.1.4.1.13742.6.3.3.6.1.21',
    inletPoleSensorLowerWarningThreshold => '1.3.6.1.4.1.13742.6.3.3.6.1.22',
    inletPoleSensorUpperCriticalThreshold => '1.3.6.1.4.1.13742.6.3.3.6.1.23',
    inletPoleSensorUpperWarningThreshold => '1.3.6.1.4.1.13742.6.3.3.6.1.24',
    inletPoleSensorEnabledThresholds => '1.3.6.1.4.1.13742.6.3.3.6.1.25',
    overCurrentProtector => '1.3.6.1.4.1.13742.6.3.4',
    overCurrentProtectorConfigurationTable => '1.3.6.1.4.1.13742.6.3.4.3',
    overCurrentProtectorConfigurationEntry => '1.3.6.1.4.1.13742.6.3.4.3.1',
    overCurrentProtectorIndex => '1.3.6.1.4.1.13742.6.3.4.3.1.1',
    overCurrentProtectorLabel => '1.3.6.1.4.1.13742.6.3.4.3.1.2',
    overCurrentProtectorName => '1.3.6.1.4.1.13742.6.3.4.3.1.3',
    overCurrentProtectorType => '1.3.6.1.4.1.13742.6.3.4.3.1.4',
    overCurrentProtectorRatedCurrent => '1.3.6.1.4.1.13742.6.3.4.3.1.5',
    overCurrentProtectorCapabilities => '1.3.6.1.4.1.13742.6.3.4.3.1.9',
    overCurrentProtectorSensorConfigurationTable => '1.3.6.1.4.1.13742.6.3.4.4',
    overCurrentProtectorSensorConfigurationEntry => '1.3.6.1.4.1.13742.6.3.4.4.1',
    overCurrentProtectorSensorLogAvailable => '1.3.6.1.4.1.13742.6.3.4.4.1.4',
    overCurrentProtectorSensorUnits => '1.3.6.1.4.1.13742.6.3.4.4.1.6',
    overCurrentProtectorSensorDecimalDigits => '1.3.6.1.4.1.13742.6.3.4.4.1.7',
    overCurrentProtectorSensorAccuracy => '1.3.6.1.4.1.13742.6.3.4.4.1.8',
    overCurrentProtectorSensorResolution => '1.3.6.1.4.1.13742.6.3.4.4.1.9',
    overCurrentProtectorSensorTolerance => '1.3.6.1.4.1.13742.6.3.4.4.1.10',
    overCurrentProtectorSensorMaximum => '1.3.6.1.4.1.13742.6.3.4.4.1.11',
    overCurrentProtectorSensorMinimum => '1.3.6.1.4.1.13742.6.3.4.4.1.12',
    overCurrentProtectorSensorHysteresis => '1.3.6.1.4.1.13742.6.3.4.4.1.13',
    overCurrentProtectorSensorStateChangeDelay => '1.3.6.1.4.1.13742.6.3.4.4.1.14',
    overCurrentProtectorSensorLowerCriticalThreshold => '1.3.6.1.4.1.13742.6.3.4.4.1.21',
    overCurrentProtectorSensorLowerWarningThreshold => '1.3.6.1.4.1.13742.6.3.4.4.1.22',
    overCurrentProtectorSensorUpperCriticalThreshold => '1.3.6.1.4.1.13742.6.3.4.4.1.23',
    overCurrentProtectorSensorUpperWarningThreshold => '1.3.6.1.4.1.13742.6.3.4.4.1.24',
    overCurrentProtectorSensorEnabledThresholds => '1.3.6.1.4.1.13742.6.3.4.4.1.25',
    outlets => '1.3.6.1.4.1.13742.6.3.5',
    outletConfigurationTable => '1.3.6.1.4.1.13742.6.3.5.3',
    outletConfigurationEntry => '1.3.6.1.4.1.13742.6.3.5.3.1',
    outletId => '1.3.6.1.4.1.13742.6.3.5.3.1.1',
    outletLabel => '1.3.6.1.4.1.13742.6.3.5.3.1.2',
    outletName => '1.3.6.1.4.1.13742.6.3.5.3.1.3',
    outletReceptacle => '1.3.6.1.4.1.13742.6.3.5.3.1.4',
    outletPoleCount => '1.3.6.1.4.1.13742.6.3.5.3.1.5',
    outletRatedVoltage => '1.3.6.1.4.1.13742.6.3.5.3.1.6',
    outletRatedCurrent => '1.3.6.1.4.1.13742.6.3.5.3.1.7',
    outletRatedVA => '1.3.6.1.4.1.13742.6.3.5.3.1.8',
    outletDeviceCapabilities => '1.3.6.1.4.1.13742.6.3.5.3.1.10',
    outletPoleCapabilities => '1.3.6.1.4.1.13742.6.3.5.3.1.11',
    outletPowerCyclingPowerOffPeriod => '1.3.6.1.4.1.13742.6.3.5.3.1.12',
    outletStateOnStartup => '1.3.6.1.4.1.13742.6.3.5.3.1.13',
    outletUseGlobalPowerCyclingPowerOffPeriod => '1.3.6.1.4.1.13742.6.3.5.3.1.14',
    outletSwitchable => '1.3.6.1.4.1.13742.6.3.5.3.1.28',
    outletReceptacleDescriptor => '1.3.6.1.4.1.13742.6.3.5.3.1.29',
    outletNonCritical => '1.3.6.1.4.1.13742.6.3.5.3.1.30',
    outletSequenceDelay => '1.3.6.1.4.1.13742.6.3.5.3.1.32',
    outletSensorConfigurationTable => '1.3.6.1.4.1.13742.6.3.5.4',
    outletSensorConfigurationEntry => '1.3.6.1.4.1.13742.6.3.5.4.1',
    outletSensorLogAvailable => '1.3.6.1.4.1.13742.6.3.5.4.1.4',
    outletSensorUnits => '1.3.6.1.4.1.13742.6.3.5.4.1.6',
    outletSensorDecimalDigits => '1.3.6.1.4.1.13742.6.3.5.4.1.7',
    outletSensorAccuracy => '1.3.6.1.4.1.13742.6.3.5.4.1.8',
    outletSensorResolution => '1.3.6.1.4.1.13742.6.3.5.4.1.9',
    outletSensorTolerance => '1.3.6.1.4.1.13742.6.3.5.4.1.10',
    outletSensorMaximum => '1.3.6.1.4.1.13742.6.3.5.4.1.11',
    outletSensorMinimum => '1.3.6.1.4.1.13742.6.3.5.4.1.12',
    outletSensorHysteresis => '1.3.6.1.4.1.13742.6.3.5.4.1.13',
    outletSensorStateChangeDelay => '1.3.6.1.4.1.13742.6.3.5.4.1.14',
    outletSensorLowerCriticalThreshold => '1.3.6.1.4.1.13742.6.3.5.4.1.21',
    outletSensorLowerWarningThreshold => '1.3.6.1.4.1.13742.6.3.5.4.1.22',
    outletSensorUpperCriticalThreshold => '1.3.6.1.4.1.13742.6.3.5.4.1.23',
    outletSensorUpperWarningThreshold => '1.3.6.1.4.1.13742.6.3.5.4.1.24',
    outletSensorEnabledThresholds => '1.3.6.1.4.1.13742.6.3.5.4.1.25',
    outletPoleSensorConfigurationTable => '1.3.6.1.4.1.13742.6.3.5.6',
    outletPoleSensorConfigurationEntry => '1.3.6.1.4.1.13742.6.3.5.6.1',
    outletPoleIndex => '1.3.6.1.4.1.13742.6.3.5.6.1.1',
    outletPoleSensorLogAvailable => '1.3.6.1.4.1.13742.6.3.5.6.1.4',
    outletPoleSensorUnits => '1.3.6.1.4.1.13742.6.3.5.6.1.6',
    outletPoleSensorDecimalDigits => '1.3.6.1.4.1.13742.6.3.5.6.1.7',
    outletPoleSensorAccuracy => '1.3.6.1.4.1.13742.6.3.5.6.1.8',
    outletPoleSensorResolution => '1.3.6.1.4.1.13742.6.3.5.6.1.9',
    outletPoleSensorTolerance => '1.3.6.1.4.1.13742.6.3.5.6.1.10',
    outletPoleSensorMaximum => '1.3.6.1.4.1.13742.6.3.5.6.1.11',
    outletPoleSensorMinimum => '1.3.6.1.4.1.13742.6.3.5.6.1.12',
    outletPoleSensorHysteresis => '1.3.6.1.4.1.13742.6.3.5.6.1.13',
    outletPoleSensorStateChangeDelay => '1.3.6.1.4.1.13742.6.3.5.6.1.14',
    outletPoleSensorLowerCriticalThreshold => '1.3.6.1.4.1.13742.6.3.5.6.1.21',
    outletPoleSensorLowerWarningThreshold => '1.3.6.1.4.1.13742.6.3.5.6.1.22',
    outletPoleSensorUpperCriticalThreshold => '1.3.6.1.4.1.13742.6.3.5.6.1.23',
    outletPoleSensorUpperWarningThreshold => '1.3.6.1.4.1.13742.6.3.5.6.1.24',
    outletPoleSensorEnabledThresholds => '1.3.6.1.4.1.13742.6.3.5.6.1.25',
    externalSensors => '1.3.6.1.4.1.13742.6.3.6',
    externalSensorConfigurationTable => '1.3.6.1.4.1.13742.6.3.6.3',
    externalSensorConfigurationEntry => '1.3.6.1.4.1.13742.6.3.6.3.1',
    sensorID => '1.3.6.1.4.1.13742.6.3.6.3.1.1',
    externalSensorType => '1.3.6.1.4.1.13742.6.3.6.3.1.2',
    externalSensorTypeDefinition => 'PDU2-MIB::SensorTypeEnumeration',
    externalSensorSerialNumber => '1.3.6.1.4.1.13742.6.3.6.3.1.3',
    externalSensorName => '1.3.6.1.4.1.13742.6.3.6.3.1.4',
    externalSensorDescription => '1.3.6.1.4.1.13742.6.3.6.3.1.5',
    externalSensorXCoordinate => '1.3.6.1.4.1.13742.6.3.6.3.1.6',
    externalSensorYCoordinate => '1.3.6.1.4.1.13742.6.3.6.3.1.7',
    externalSensorZCoordinate => '1.3.6.1.4.1.13742.6.3.6.3.1.8',
    externalSensorChannelNumber => '1.3.6.1.4.1.13742.6.3.6.3.1.9',
    externalOnOffSensorSubtype => '1.3.6.1.4.1.13742.6.3.6.3.1.10',
    externalOnOffSensorSubtypeDefinition => 'PDU2-MIB::SensorTypeEnumeration',
    externalSensorLogAvailable => '1.3.6.1.4.1.13742.6.3.6.3.1.14',
    externalSensorUnits => '1.3.6.1.4.1.13742.6.3.6.3.1.16',
    externalSensorUnitsDefinition => 'PDU2-MIB::SensorUnitsEnumeration',
    externalSensorDecimalDigits => '1.3.6.1.4.1.13742.6.3.6.3.1.17',
    externalSensorAccuracy => '1.3.6.1.4.1.13742.6.3.6.3.1.18',
    externalSensorResolution => '1.3.6.1.4.1.13742.6.3.6.3.1.19',
    externalSensorTolerance => '1.3.6.1.4.1.13742.6.3.6.3.1.20',
    externalSensorMaximum => '1.3.6.1.4.1.13742.6.3.6.3.1.21',
    externalSensorMinimum => '1.3.6.1.4.1.13742.6.3.6.3.1.22',
    externalSensorHysteresis => '1.3.6.1.4.1.13742.6.3.6.3.1.23',
    externalSensorStateChangeDelay => '1.3.6.1.4.1.13742.6.3.6.3.1.24',
    externalSensorLowerCriticalThreshold => '1.3.6.1.4.1.13742.6.3.6.3.1.31',
    externalSensorLowerWarningThreshold => '1.3.6.1.4.1.13742.6.3.6.3.1.32',
    externalSensorUpperCriticalThreshold => '1.3.6.1.4.1.13742.6.3.6.3.1.33',
    externalSensorUpperWarningThreshold => '1.3.6.1.4.1.13742.6.3.6.3.1.34',
    externalSensorEnabledThresholds => '1.3.6.1.4.1.13742.6.3.6.3.1.35',
    serverReachability => '1.3.6.1.4.1.13742.6.3.7',
    serverReachabilityTable => '1.3.6.1.4.1.13742.6.3.7.3',
    serverReachabilityEntry => '1.3.6.1.4.1.13742.6.3.7.3.1',
    serverID => '1.3.6.1.4.1.13742.6.3.7.3.1.1',
    serverIPAddress => '1.3.6.1.4.1.13742.6.3.7.3.1.3',
    serverPingEnabled => '1.3.6.1.4.1.13742.6.3.7.3.1.4',
    wires => '1.3.6.1.4.1.13742.6.3.8',
    wireConfigurationTable => '1.3.6.1.4.1.13742.6.3.8.3',
    wireConfigurationEntry => '1.3.6.1.4.1.13742.6.3.8.3.1',
    wireId => '1.3.6.1.4.1.13742.6.3.8.3.1.1',
    wireLabel => '1.3.6.1.4.1.13742.6.3.8.3.1.2',
    wireCapabilities => '1.3.6.1.4.1.13742.6.3.8.3.1.3',
    wireSensorConfigurationTable => '1.3.6.1.4.1.13742.6.3.8.4',
    wireSensorConfigurationEntry => '1.3.6.1.4.1.13742.6.3.8.4.1',
    wireSensorLogAvailable => '1.3.6.1.4.1.13742.6.3.8.4.1.4',
    wireSensorUnits => '1.3.6.1.4.1.13742.6.3.8.4.1.6',
    wireSensorDecimalDigits => '1.3.6.1.4.1.13742.6.3.8.4.1.7',
    wireSensorAccuracy => '1.3.6.1.4.1.13742.6.3.8.4.1.8',
    wireSensorResolution => '1.3.6.1.4.1.13742.6.3.8.4.1.9',
    wireSensorTolerance => '1.3.6.1.4.1.13742.6.3.8.4.1.10',
    wireSensorMaximum => '1.3.6.1.4.1.13742.6.3.8.4.1.11',
    wireSensorMinimum => '1.3.6.1.4.1.13742.6.3.8.4.1.12',
    wireSensorHysteresis => '1.3.6.1.4.1.13742.6.3.8.4.1.13',
    wireSensorStateChangeDelay => '1.3.6.1.4.1.13742.6.3.8.4.1.14',
    wireSensorLowerCriticalThreshold => '1.3.6.1.4.1.13742.6.3.8.4.1.21',
    wireSensorLowerWarningThreshold => '1.3.6.1.4.1.13742.6.3.8.4.1.22',
    wireSensorUpperCriticalThreshold => '1.3.6.1.4.1.13742.6.3.8.4.1.23',
    wireSensorUpperWarningThreshold => '1.3.6.1.4.1.13742.6.3.8.4.1.24',
    wireSensorEnabledThresholds => '1.3.6.1.4.1.13742.6.3.8.4.1.25',
    transferSwitch => '1.3.6.1.4.1.13742.6.3.9',
    transferSwitchConfigurationTable => '1.3.6.1.4.1.13742.6.3.9.3',
    transferSwitchConfigurationEntry => '1.3.6.1.4.1.13742.6.3.9.3.1',
    transferSwitchId => '1.3.6.1.4.1.13742.6.3.9.3.1.1',
    transferSwitchLabel => '1.3.6.1.4.1.13742.6.3.9.3.1.2',
    transferSwitchName => '1.3.6.1.4.1.13742.6.3.9.3.1.3',
    transferSwitchPreferredInlet => '1.3.6.1.4.1.13742.6.3.9.3.1.4',
    transferSwitchLowerFailVoltage => '1.3.6.1.4.1.13742.6.3.9.3.1.5',
    transferSwitchLowerMarginalVoltage => '1.3.6.1.4.1.13742.6.3.9.3.1.6',
    transferSwitchUpperFailVoltage => '1.3.6.1.4.1.13742.6.3.9.3.1.7',
    transferSwitchUpperMarginalVoltage => '1.3.6.1.4.1.13742.6.3.9.3.1.8',
    transferSwitchVoltageHysteresis => '1.3.6.1.4.1.13742.6.3.9.3.1.9',
    transferSwitchVoltageDetectTime => '1.3.6.1.4.1.13742.6.3.9.3.1.10',
    transferSwitchLowerMarginalFrequency => '1.3.6.1.4.1.13742.6.3.9.3.1.11',
    transferSwitchUpperMarginalFrequency => '1.3.6.1.4.1.13742.6.3.9.3.1.12',
    transferSwitchFrequencyHysteresis => '1.3.6.1.4.1.13742.6.3.9.3.1.13',
    transferSwitchAutoReTransferEnabled => '1.3.6.1.4.1.13742.6.3.9.3.1.16',
    transferSwitchAutoReTransferWaitTime => '1.3.6.1.4.1.13742.6.3.9.3.1.17',
    transferSwitchAutoReTransferRequiresPhaseSync => '1.3.6.1.4.1.13742.6.3.9.3.1.18',
    transferSwitchFrontPanelManualTransferButtonEnabled => '1.3.6.1.4.1.13742.6.3.9.3.1.19',
    transferSwitchCapabilities => '1.3.6.1.4.1.13742.6.3.9.3.1.20',
    transferSwitchSensorConfigurationTable => '1.3.6.1.4.1.13742.6.3.9.4',
    transferSwitchSensorConfigurationEntry => '1.3.6.1.4.1.13742.6.3.9.4.1',
    transferSwitchSensorLogAvailable => '1.3.6.1.4.1.13742.6.3.9.4.1.4',
    transferSwitchSensorUnits => '1.3.6.1.4.1.13742.6.3.9.4.1.6',
    transferSwitchSensorDecimalDigits => '1.3.6.1.4.1.13742.6.3.9.4.1.7',
    transferSwitchSensorAccuracy => '1.3.6.1.4.1.13742.6.3.9.4.1.8',
    transferSwitchSensorResolution => '1.3.6.1.4.1.13742.6.3.9.4.1.9',
    transferSwitchSensorTolerance => '1.3.6.1.4.1.13742.6.3.9.4.1.10',
    transferSwitchSensorSignedMaximum => '1.3.6.1.4.1.13742.6.3.9.4.1.11',
    transferSwitchSensorSignedMinimum => '1.3.6.1.4.1.13742.6.3.9.4.1.12',
    transferSwitchSensorHysteresis => '1.3.6.1.4.1.13742.6.3.9.4.1.13',
    transferSwitchSensorStateChangeDelay => '1.3.6.1.4.1.13742.6.3.9.4.1.14',
    transferSwitchSensorSignedLowerCriticalThreshold => '1.3.6.1.4.1.13742.6.3.9.4.1.21',
    transferSwitchSensorSignedLowerWarningThreshold => '1.3.6.1.4.1.13742.6.3.9.4.1.22',
    transferSwitchSensorSignedUpperCriticalThreshold => '1.3.6.1.4.1.13742.6.3.9.4.1.23',
    transferSwitchSensorSignedUpperWarningThreshold => '1.3.6.1.4.1.13742.6.3.9.4.1.24',
    transferSwitchSensorEnabledThresholds => '1.3.6.1.4.1.13742.6.3.9.4.1.25',
    control => '1.3.6.1.4.1.13742.6.4',
    outletControl => '1.3.6.1.4.1.13742.6.4.1',
    outletSwitchControlTable => '1.3.6.1.4.1.13742.6.4.1.2',
    outletSwitchControlEntry => '1.3.6.1.4.1.13742.6.4.1.2.1',
    switchingOperation => '1.3.6.1.4.1.13742.6.4.1.2.1.2',
    outletSwitchingState => '1.3.6.1.4.1.13742.6.4.1.2.1.3',
    outletSwitchingTimeStamp => '1.3.6.1.4.1.13742.6.4.1.2.1.4',
    externalSensorControl => '1.3.6.1.4.1.13742.6.4.2',
    transferSwitchControl => '1.3.6.1.4.1.13742.6.4.3',
    transferSwitchControlTable => '1.3.6.1.4.1.13742.6.4.3.1',
    transferSwitchControlEntry => '1.3.6.1.4.1.13742.6.4.3.1.1',
    transferSwitchActiveInlet => '1.3.6.1.4.1.13742.6.4.3.1.1.1',
    transferSwitchTransferToInlet => '1.3.6.1.4.1.13742.6.4.3.1.1.2',
    transferSwitchAlarmOverride => '1.3.6.1.4.1.13742.6.4.3.1.1.3',
    measurements => '1.3.6.1.4.1.13742.6.5',
    measurementsUnit => '1.3.6.1.4.1.13742.6.5.1',
    unitSensorMeasurementsTable => '1.3.6.1.4.1.13742.6.5.1.3',
    unitSensorMeasurementsEntry => '1.3.6.1.4.1.13742.6.5.1.3.1',
    measurementsUnitSensorIsAvailable => '1.3.6.1.4.1.13742.6.5.1.3.1.2',
    measurementsUnitSensorState => '1.3.6.1.4.1.13742.6.5.1.3.1.3',
    measurementsUnitSensorValue => '1.3.6.1.4.1.13742.6.5.1.3.1.4',
    measurementsUnitSensorTimeStamp => '1.3.6.1.4.1.13742.6.5.1.3.1.5',
    measurementsInlet => '1.3.6.1.4.1.13742.6.5.2',
    inletSensorMeasurementsTable => '1.3.6.1.4.1.13742.6.5.2.3',
    inletSensorMeasurementsEntry => '1.3.6.1.4.1.13742.6.5.2.3.1',
    measurementsInletSensorIsAvailable => '1.3.6.1.4.1.13742.6.5.2.3.1.2',
    measurementsInletSensorIsAvailableDefinition => 'PDU2-MIB::TruthValue',
    measurementsInletSensorState => '1.3.6.1.4.1.13742.6.5.2.3.1.3',
    measurementsInletSensorStateDefinition => 'PDU2-MIB::SensorStateEnumeration',
    measurementsInletSensorValue => '1.3.6.1.4.1.13742.6.5.2.3.1.4',
    measurementsInletSensorTimeStamp => '1.3.6.1.4.1.13742.6.5.2.3.1.5',
    inletPoleSensorMeasurementsTable => '1.3.6.1.4.1.13742.6.5.2.4',
    inletPoleSensorMeasurementsEntry => '1.3.6.1.4.1.13742.6.5.2.4.1',
    measurementsInletPoleSensorIsAvailable => '1.3.6.1.4.1.13742.6.5.2.4.1.2',
    measurementsInletPoleSensorState => '1.3.6.1.4.1.13742.6.5.2.4.1.3',
    measurementsInletPoleSensorValue => '1.3.6.1.4.1.13742.6.5.2.4.1.4',
    measurementsInletPoleSensorTimeStamp => '1.3.6.1.4.1.13742.6.5.2.4.1.5',
    measurementsOverCurrentProtector => '1.3.6.1.4.1.13742.6.5.3',
    overCurrentProtectorSensorMeasurementsTable => '1.3.6.1.4.1.13742.6.5.3.3',
    overCurrentProtectorSensorMeasurementsEntry => '1.3.6.1.4.1.13742.6.5.3.3.1',
    measurementsOverCurrentProtectorSensorIsAvailable => '1.3.6.1.4.1.13742.6.5.3.3.1.2',
    measurementsOverCurrentProtectorSensorState => '1.3.6.1.4.1.13742.6.5.3.3.1.3',
    measurementsOverCurrentProtectorSensorValue => '1.3.6.1.4.1.13742.6.5.3.3.1.4',
    measurementsOverCurrentProtectorSensorTimeStamp => '1.3.6.1.4.1.13742.6.5.3.3.1.5',
    measurementsOutlet => '1.3.6.1.4.1.13742.6.5.4',
    outletSensorMeasurementsTable => '1.3.6.1.4.1.13742.6.5.4.3',
    outletSensorMeasurementsEntry => '1.3.6.1.4.1.13742.6.5.4.3.1',
    measurementsOutletSensorIsAvailable => '1.3.6.1.4.1.13742.6.5.4.3.1.2',
    measurementsOutletSensorState => '1.3.6.1.4.1.13742.6.5.4.3.1.3',
    measurementsOutletSensorValue => '1.3.6.1.4.1.13742.6.5.4.3.1.4',
    measurementsOutletSensorTimeStamp => '1.3.6.1.4.1.13742.6.5.4.3.1.5',
    outletPoleSensorMeasurementsTable => '1.3.6.1.4.1.13742.6.5.4.4',
    outletPoleSensorMeasurementsEntry => '1.3.6.1.4.1.13742.6.5.4.4.1',
    measurementsOutletPoleSensorIsAvailable => '1.3.6.1.4.1.13742.6.5.4.4.1.2',
    measurementsOutletPoleSensorState => '1.3.6.1.4.1.13742.6.5.4.4.1.3',
    measurementsOutletPoleSensorValue => '1.3.6.1.4.1.13742.6.5.4.4.1.4',
    measurementsOutletPoleSensorTimeStamp => '1.3.6.1.4.1.13742.6.5.4.4.1.5',
    measurementsExternalSensor => '1.3.6.1.4.1.13742.6.5.5',
    externalSensorMeasurementsTable => '1.3.6.1.4.1.13742.6.5.5.3',
    externalSensorMeasurementsEntry => '1.3.6.1.4.1.13742.6.5.5.3.1',
    measurementsExternalSensorIsAvailable => '1.3.6.1.4.1.13742.6.5.5.3.1.2',
    measurementsExternalSensorIsAvailableDefinition => 'PDU2-MIB::TruthValue',
    measurementsExternalSensorState => '1.3.6.1.4.1.13742.6.5.5.3.1.3',
    measurementsExternalSensorStateDefinition => 'PDU2-MIB::SensorStateEnumeration',
    measurementsExternalSensorValue => '1.3.6.1.4.1.13742.6.5.5.3.1.4',
    measurementsExternalSensorTimeStamp => '1.3.6.1.4.1.13742.6.5.5.3.1.5',
    measurementsWire => '1.3.6.1.4.1.13742.6.5.6',
    wireSensorMeasurementsTable => '1.3.6.1.4.1.13742.6.5.6.3',
    wireSensorMeasurementsEntry => '1.3.6.1.4.1.13742.6.5.6.3.1',
    measurementsWireSensorIsAvailable => '1.3.6.1.4.1.13742.6.5.6.3.1.2',
    measurementsWireSensorState => '1.3.6.1.4.1.13742.6.5.6.3.1.3',
    measurementsWireSensorValue => '1.3.6.1.4.1.13742.6.5.6.3.1.4',
    measurementsWireSensorTimeStamp => '1.3.6.1.4.1.13742.6.5.6.3.1.5',
    measurementsTransferSwitch => '1.3.6.1.4.1.13742.6.5.7',
    transferSwitchSensorMeasurementsTable => '1.3.6.1.4.1.13742.6.5.7.3',
    transferSwitchSensorMeasurementsEntry => '1.3.6.1.4.1.13742.6.5.7.3.1',
    measurementsTransferSwitchSensorIsAvailable => '1.3.6.1.4.1.13742.6.5.7.3.1.2',
    measurementsTransferSwitchSensorState => '1.3.6.1.4.1.13742.6.5.7.3.1.3',
    measurementsTransferSwitchSensorSignedValue => '1.3.6.1.4.1.13742.6.5.7.3.1.4',
    measurementsTransferSwitchSensorTimeStamp => '1.3.6.1.4.1.13742.6.5.7.3.1.5',
    log => '1.3.6.1.4.1.13742.6.6',
    logUnit => '1.3.6.1.4.1.13742.6.6.1',
    logIndexTable => '1.3.6.1.4.1.13742.6.6.1.1',
    logIndexEntry => '1.3.6.1.4.1.13742.6.6.1.1.1',
    oldestLogID => '1.3.6.1.4.1.13742.6.6.1.1.1.2',
    newestLogID => '1.3.6.1.4.1.13742.6.6.1.1.1.3',
    logTimeStampTable => '1.3.6.1.4.1.13742.6.6.1.2',
    logTimeStampEntry => '1.3.6.1.4.1.13742.6.6.1.2.1',
    logIndex => '1.3.6.1.4.1.13742.6.6.1.2.1.1',
    logTimeStamp => '1.3.6.1.4.1.13742.6.6.1.2.1.2',
    unitSensorLogTable => '1.3.6.1.4.1.13742.6.6.1.3',
    unitSensorLogEntry => '1.3.6.1.4.1.13742.6.6.1.3.1',
    logUnitSensorDataAvailable => '1.3.6.1.4.1.13742.6.6.1.3.1.2',
    logUnitSensorState => '1.3.6.1.4.1.13742.6.6.1.3.1.3',
    logUnitSensorAvgValue => '1.3.6.1.4.1.13742.6.6.1.3.1.4',
    logUnitSensorMaxValue => '1.3.6.1.4.1.13742.6.6.1.3.1.5',
    logUnitSensorMinValue => '1.3.6.1.4.1.13742.6.6.1.3.1.6',
    logInlet => '1.3.6.1.4.1.13742.6.6.2',
    inletSensorLogTable => '1.3.6.1.4.1.13742.6.6.2.3',
    inletSensorLogEntry => '1.3.6.1.4.1.13742.6.6.2.3.1',
    logInletSensorDataAvailable => '1.3.6.1.4.1.13742.6.6.2.3.1.2',
    logInletSensorState => '1.3.6.1.4.1.13742.6.6.2.3.1.3',
    logInletSensorAvgValue => '1.3.6.1.4.1.13742.6.6.2.3.1.4',
    logInletSensorMaxValue => '1.3.6.1.4.1.13742.6.6.2.3.1.5',
    logInletSensorMinValue => '1.3.6.1.4.1.13742.6.6.2.3.1.6',
    inletPoleSensorLogTable => '1.3.6.1.4.1.13742.6.6.2.4',
    inletPoleSensorLogEntry => '1.3.6.1.4.1.13742.6.6.2.4.1',
    logInletPoleSensorDataAvailable => '1.3.6.1.4.1.13742.6.6.2.4.1.2',
    logInletPoleSensorState => '1.3.6.1.4.1.13742.6.6.2.4.1.3',
    logInletPoleSensorAvgValue => '1.3.6.1.4.1.13742.6.6.2.4.1.4',
    logInletPoleSensorMaxValue => '1.3.6.1.4.1.13742.6.6.2.4.1.5',
    logInletPoleSensorMinValue => '1.3.6.1.4.1.13742.6.6.2.4.1.6',
    logOverCurrentProtector => '1.3.6.1.4.1.13742.6.6.3',
    overCurrentProtectorSensorLogTable => '1.3.6.1.4.1.13742.6.6.3.3',
    overCurrentProtectorSensorLogEntry => '1.3.6.1.4.1.13742.6.6.3.3.1',
    logOverCurrentProtectorSensorDataAvailable => '1.3.6.1.4.1.13742.6.6.3.3.1.2',
    logOverCurrentProtectorSensorState => '1.3.6.1.4.1.13742.6.6.3.3.1.3',
    logOverCurrentProtectorSensorAvgValue => '1.3.6.1.4.1.13742.6.6.3.3.1.4',
    logOverCurrentProtectorSensorMaxValue => '1.3.6.1.4.1.13742.6.6.3.3.1.5',
    logOverCurrentProtectorSensorMinValue => '1.3.6.1.4.1.13742.6.6.3.3.1.6',
    logOutlet => '1.3.6.1.4.1.13742.6.6.4',
    outletSensorLogTable => '1.3.6.1.4.1.13742.6.6.4.3',
    outletSensorLogEntry => '1.3.6.1.4.1.13742.6.6.4.3.1',
    logOutletSensorDataAvailable => '1.3.6.1.4.1.13742.6.6.4.3.1.2',
    logOutletSensorState => '1.3.6.1.4.1.13742.6.6.4.3.1.3',
    logOutletSensorAvgValue => '1.3.6.1.4.1.13742.6.6.4.3.1.4',
    logOutletSensorMaxValue => '1.3.6.1.4.1.13742.6.6.4.3.1.5',
    logOutletSensorMinValue => '1.3.6.1.4.1.13742.6.6.4.3.1.6',
    outletPoleSensorLogTable => '1.3.6.1.4.1.13742.6.6.4.4',
    outletPoleSensorLogEntry => '1.3.6.1.4.1.13742.6.6.4.4.1',
    logOutletPoleSensorDataAvailable => '1.3.6.1.4.1.13742.6.6.4.4.1.2',
    logOutletPoleSensorState => '1.3.6.1.4.1.13742.6.6.4.4.1.3',
    logOutletPoleSensorAvgValue => '1.3.6.1.4.1.13742.6.6.4.4.1.4',
    logOutletPoleSensorMaxValue => '1.3.6.1.4.1.13742.6.6.4.4.1.5',
    logOutletPoleSensorMinValue => '1.3.6.1.4.1.13742.6.6.4.4.1.6',
    logExternalSensor => '1.3.6.1.4.1.13742.6.6.5',
    externalSensorLogTable => '1.3.6.1.4.1.13742.6.6.5.3',
    externalSensorLogEntry => '1.3.6.1.4.1.13742.6.6.5.3.1',
    logExternalSensorDataAvailable => '1.3.6.1.4.1.13742.6.6.5.3.1.2',
    logExternalSensorState => '1.3.6.1.4.1.13742.6.6.5.3.1.3',
    logExternalSensorAvgValue => '1.3.6.1.4.1.13742.6.6.5.3.1.4',
    logExternalSensorMaxValue => '1.3.6.1.4.1.13742.6.6.5.3.1.5',
    logExternalSensorMinValue => '1.3.6.1.4.1.13742.6.6.5.3.1.6',
    logWire => '1.3.6.1.4.1.13742.6.6.6',
    wireSensorLogTable => '1.3.6.1.4.1.13742.6.6.6.3',
    wireSensorLogEntry => '1.3.6.1.4.1.13742.6.6.6.3.1',
    logWireSensorDataAvailable => '1.3.6.1.4.1.13742.6.6.6.3.1.2',
    logWireSensorState => '1.3.6.1.4.1.13742.6.6.6.3.1.3',
    logWireSensorAvgValue => '1.3.6.1.4.1.13742.6.6.6.3.1.4',
    logWireSensorMaxValue => '1.3.6.1.4.1.13742.6.6.6.3.1.5',
    logWireSensorMinValue => '1.3.6.1.4.1.13742.6.6.6.3.1.6',
    logTransferSwitch => '1.3.6.1.4.1.13742.6.6.7',
    transferSwitchSensorLogTable => '1.3.6.1.4.1.13742.6.6.7.3',
    transferSwitchSensorLogEntry => '1.3.6.1.4.1.13742.6.6.7.3.1',
    logTransferSwitchSensorDataAvailable => '1.3.6.1.4.1.13742.6.6.7.3.1.2',
    logTransferSwitchSensorState => '1.3.6.1.4.1.13742.6.6.7.3.1.3',
    logTransferSwitchSensorSignedAvgValue => '1.3.6.1.4.1.13742.6.6.7.3.1.7',
    logTransferSwitchSensorSignedMaxValue => '1.3.6.1.4.1.13742.6.6.7.3.1.8',
    logTransferSwitchSensorSignedMinValue => '1.3.6.1.4.1.13742.6.6.7.3.1.9',
    conformance => '1.3.6.1.4.1.13742.6.9',
    compliances => '1.3.6.1.4.1.13742.6.9.1',
    groups => '1.3.6.1.4.1.13742.6.9.2',
    reliability => '1.3.6.1.4.1.13742.6.10',
    reliabilityData => '1.3.6.1.4.1.13742.6.10.1',
    reliabilityDataTableSequenceNumber => '1.3.6.1.4.1.13742.6.10.1.1',
    reliabilityDataTable => '1.3.6.1.4.1.13742.6.10.1.2',
    reliabilityDataEntry => '1.3.6.1.4.1.13742.6.10.1.2.1',
    reliabilityIndex => '1.3.6.1.4.1.13742.6.10.1.2.1.1',
    reliabilityId => '1.3.6.1.4.1.13742.6.10.1.2.1.2',
    reliabilityDataValue => '1.3.6.1.4.1.13742.6.10.1.2.1.3',
    reliabilityDataMaxPossible => '1.3.6.1.4.1.13742.6.10.1.2.1.4',
    reliabilityDataWorstValue => '1.3.6.1.4.1.13742.6.10.1.2.1.5',
    reliabilityDataThreshold => '1.3.6.1.4.1.13742.6.10.1.2.1.6',
    reliabilityDataRawUpperBytes => '1.3.6.1.4.1.13742.6.10.1.2.1.7',
    reliabilityDataRawLowerBytes => '1.3.6.1.4.1.13742.6.10.1.2.1.8',
    reliabilityDataFlags => '1.3.6.1.4.1.13742.6.10.1.2.1.9',
    reliabilityErrorLog => '1.3.6.1.4.1.13742.6.10.2',
    reliabilityErrorLogTable => '1.3.6.1.4.1.13742.6.10.2.2',
    reliabilityErrorLogEntry => '1.3.6.1.4.1.13742.6.10.2.2.1',
    reliabilityErrorLogIndex => '1.3.6.1.4.1.13742.6.10.2.2.1.1',
    reliabilityErrorLogId => '1.3.6.1.4.1.13742.6.10.2.2.1.2',
    reliabilityErrorLogValue => '1.3.6.1.4.1.13742.6.10.2.2.1.3',
    reliabilityErrorLogThreshold => '1.3.6.1.4.1.13742.6.10.2.2.1.6',
    reliabilityErrorLogRawUpperBytes => '1.3.6.1.4.1.13742.6.10.2.2.1.7',
    reliabilityErrorLogRawLowerBytes => '1.3.6.1.4.1.13742.6.10.2.2.1.8',
    reliabilityErrorLogPOH => '1.3.6.1.4.1.13742.6.10.2.2.1.9',
    reliabilityErrorLogTime => '1.3.6.1.4.1.13742.6.10.2.2.1.10',
  },
};
$MyRaritan::definitions = {
  'PDU2-MIB' => {
    'SensorTypeEnumeration' => {
      1 => 'rmsCurrent',
      2 => 'peakCurrent',
      3 => 'unbalancedCurrent',
      4 => 'rmsVoltage',
      5 => 'activePower',
      6 => 'apparentPower',
      7 => 'powerFactor',
      8 => 'activeEnergy',
      9 => 'apparentEnergy',
      10 => 'temperature',
      11 => 'humidity',
      12 => 'airFlow',
      13 => 'airPressure',
      14 => 'onOff',
      15 => 'trip',
      16 => 'vibration',
      17 => 'waterDetection',
      18 => 'smokeDetection',
      19 => 'binary',
      20 => 'contact',
      21 => 'fanSpeed',
      22 => 'surgeProtectorStatus',
      23 => 'frequency',
      24 => 'phaseAngle',
      30 => 'other',
      31 => 'none',
      32 => 'powerQuality',
      33 => 'overloadStatus',
      34 => 'overheatStatus',
      35 => 'scrOpenStatus',
      36 => 'scrShortStatus',
      37 => 'fanStatus',
      38 => 'inletPhaseSyncAngle',
      39 => 'inletPhaseSync',
      40 => 'operatingState',
      41 => 'activeInlet',
    },
    'SensorStateEnumeration' => {
      -1 => 'unavailable',
      0 => 'open',
      1 => 'closed',
      2 => 'belowLowerCritical',
      3 => 'belowLowerWarning',
      4 => 'normal',
      5 => 'aboveUpperWarning',
      6 => 'aboveUpperCritical',
      7 => 'on',
      8 => 'off',
      9 => 'detected',
      10 => 'notDetected',
      11 => 'alarmed',
      12 => 'ok',
      13 => 'marginal',
      14 => 'fail',
      15 => 'yes',
      16 => 'no',
      17 => 'standby',
      18 => 'one',
      19 => 'two',
      20 => 'inSync',
      21 => 'outOfSync',
    },
    'SensorUnitsEnumeration' => {
      -1 => 'none',
      0 => 'other',
      1 => 'volt',
      2 => 'amp',
      3 => 'watt',
      4 => 'voltamp',
      5 => 'wattHour',
      6 => 'voltampHour',
      7 => 'degreeC',
      8 => 'hertz',
      9 => 'percent',
      10 => 'meterpersec',
      11 => 'pascal',
      12 => 'psi',
      13 => 'g',
      14 => 'degreeF',
      15 => 'feet',
      16 => 'inches',
      17 => 'cm',
      18 => 'meters',
      19 => 'rpm',
      20 => 'degrees',
    },
    'inletDeviceCapabilities' => {
      0 => 'rmsCurrent',
      1 => 'peakCurrent',
      2 => 'unbalancedCurrent',
      3 => 'rmsVoltage',
      4 => 'activePower',
      5 => 'apparentPower',
      6 => 'powerFactor',
      7 => 'activeEnergy',
      8 => 'apparentEnergy',
      21 => 'surgeProtectorStatus',
      22 => 'frequency',
      23 => 'phaseAngle',
      31 => 'powerQuality',
    },
    'inletPoleCapabilities' => {
      0 => 'rmsCurrent',
      1 => 'peakCurrent',
      3 => 'rmsVoltage',
      4 => 'activePower',
      5 => 'apparentPower',
      6 => 'powerFactor',
      7 => 'activeEnergy',
      8 => 'apparentEnergy',
    },
    'inletSensorEnabledThresholds' => {
      0 => 'lowerCritical',
      1 => 'lowerWarning',
      2 => 'upperWarning',
      3 => 'upperCritical',
    },
    'inletPoleSensorEnabledThresholds' => {
      0 => 'lowerCritical',
      1 => 'lowerWarning',
      2 => 'upperWarning',
      3 => 'upperCritical',
    },
    'overCurrentProtectorCapabilities' => {
      0 => 'rmsCurrent',
      1 => 'peakCurrent',
      14 => 'trip',
    },
    'overCurrentProtectorSensorEnabledThresholds' => {
      0 => 'lowerCritical',
      1 => 'lowerWarning',
      2 => 'upperWarning',
      3 => 'upperCritical',
    },
    'outletDeviceCapabilities' => {
      0 => 'rmsCurrent',
      1 => 'peakCurrent',
      2 => 'unbalancedCurrent',
      3 => 'rmsVoltage',
      4 => 'activePower',
      5 => 'apparentPower',
      6 => 'powerFactor',
      7 => 'activeEnergy',
      8 => 'apparentEnergy',
      21 => 'surgeProtectorStatus',
      22 => 'frequency',
      23 => 'phaseAngle',
    },
    'outletPoleCapabilities' => {
      0 => 'rmsCurrent',
      1 => 'peakCurrent',
      3 => 'rmsVoltage',
      4 => 'activePower',
      5 => 'apparentPower',
      6 => 'powerFactor',
      7 => 'activeEnergy',
      8 => 'apparentEnergy',
    },
    'outletSensorEnabledThresholds' => {
      0 => 'lowerCritical',
      1 => 'lowerWarning',
      2 => 'upperWarning',
      3 => 'upperCritical',
    },
    'outletPoleSensorEnabledThresholds' => {
      0 => 'lowerCritical',
      1 => 'lowerWarning',
      2 => 'upperWarning',
      3 => 'upperCritical',
    },
    'externalSensorEnabledThresholds' => {
      0 => 'lowerCritical',
      1 => 'lowerWarning',
      2 => 'upperWarning',
      3 => 'upperCritical',
    },
    'wireCapabilities' => {
      0 => 'rmsCurrent',
      1 => 'peakCurrent',
      2 => 'unbalancedCurrent',
      3 => 'rmsVoltage',
      4 => 'activePower',
      5 => 'apparentPower',
      6 => 'powerFactor',
      7 => 'activeEnergy',
      8 => 'apparentEnergy',
    },
    'wireSensorEnabledThresholds' => {
      0 => 'lowerCritical',
      1 => 'lowerWarning',
      2 => 'upperWarning',
      3 => 'upperCritical',
    },
    'transferSwitchCapabilities' => {
      9 => 'temperature',
      21 => 'surgeProtectorStatus',
      32 => 'overloadStatus',
      33 => 'overheatStatus',
      34 => 'scrOpenStatus',
      35 => 'scrShortStatus',
      36 => 'fanStatus',
      37 => 'inletPhaseSyncAngle',
      38 => 'inletPhaseSync',
      39 => 'operatingState',
      40 => 'activeInlet',
    },
    'transferSwitchSensorEnabledThresholds' => {
      0 => 'lowerCritical',
      1 => 'lowerWarning',
      2 => 'upperWarning',
      3 => 'upperCritical',
    },
    'TruthValue' => {
      1 => 'true',
      2 => 'false',
    }
  }
}

