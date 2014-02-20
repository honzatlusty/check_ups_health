package Classes::V4::Components::EnvironmentalSubsystem;
our @ISA = qw(Classes::V4);
use strict;

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->init();
  return $self;
}

sub init {
  my $self = shift;
  $self->get_snmp_objects('UPSV4-MIB', (qw(
      dupsEnvTemperature dupsAlarmOverEnvHumidity dupsAlarmEnvRelay1 
      dupsAlarmEnvRelay2 dupsAlarmEnvRelay3 dupsAlarmEnvRelay4 
      dupsEnvHumidity dupsEnvSetTemperatureLimit dupsEnvSetHumidityLimit 
      dupsEnvSetEnvRelay1 dupsEnvSetEnvRelay2 dupsEnvSetEnvRelay3
      dupsEnvSetEnvRelay4 dupsAlarmOverEnvTemperature
      dupsTemperature)));
  $self->{dupsEnvTemperature} ||= $self->{dupsTemperature};
  $self->get_snmp_objects('UPSV4-MIB', (qw(
      dupsAlarmDisconnect dupsAlarmBatteryTestFail
      dupsAlarmFuseFailure dupsAlarmOutputOverload dupsAlarmOutputOverCurrent
      dupsAlarmInverterAbnormal dupsAlarmRectifierAbnormal
      dupsAlarmReserveAbnormal dupsAlarmLoadOnReserve 
      dupsAlarmOverTemperature dupsAlarmOutputBad dupsAlarmPowerFail
      dupsAlarmBypassBad dupsAlarmClassesOff dupsAlarmChargerFail
      dupsAlarmFanFail dupsAlarmEconomicMode dupsAlarmOutputOff
      dupsAlarmSmartShutdown dupsAlarmEmergencyPowerOff
      dupsAlarmBatteryLow dupsAlarmLoadWarning dupsAlarmLoadSeverity
      dupsAlarmLoadOnBypass dupsAlarmClassesFault dupsAlarmBatteryGroundFault
      dupsAlarmTestInProgress)));
}

sub check {
  my $self = shift;
  $self->add_info('checking environment');
  my $info = sprintf 'temperature %dC',
      $self->{dupsEnvTemperature};
  if ($self->{dupsEnvHumidity}) {
    $info .= sprintf ', humidity %d%%', $self->{dupsEnvHumidity};
  }
  $self->add_ok($info);
  $self->add_info($info);
  my $alarms = 0;
  foreach (qw(dupsAlarmDisconnect dupsAlarmBatteryTestFail
      dupsAlarmFuseFailure dupsAlarmOutputOverload dupsAlarmOutputOverCurrent
      dupsAlarmInverterAbnormal dupsAlarmRectifierAbnormal
      dupsAlarmReserveAbnormal dupsAlarmLoadOnReserve
      dupsAlarmOverTemperature dupsAlarmOutputBad dupsAlarmPowerFail
      dupsAlarmBypassBad dupsAlarmClassesOff dupsAlarmChargerFail
      dupsAlarmFanFail dupsAlarmEconomicMode dupsAlarmOutputOff
      dupsAlarmSmartShutdown dupsAlarmEmergencyPowerOff
      dupsAlarmBatteryLow dupsAlarmLoadWarning dupsAlarmLoadSeverity
      dupsAlarmLoadOnBypass dupsAlarmClassesFault dupsAlarmBatteryGroundFault
      dupsAlarmTestInProgress)) {
    if ($self->{$_} && $self->{$_} eq 'on') {
      $self->add_critical(sprintf 'alarm %s is on', $_);
      $alarms++;
    }
  }
  if ($self->{dupsAlarmOverEnvTemperature} eq 'on') {
    $self->add_critical(sprintf 'temperature too high, %d max',
        $self->{dupsEnvSetTemperatureLimit});
    $alarms++;
  }
  if ($self->{dupsAlarmOverEnvHumidity} eq 'on') {
    $self->add_critical(sprintf 'humidity too high, %d max',
        $self->{dupsEnvSetHumidityLimit});
    $alarms++;
  }
  if (! $alarms) {
    $self->add_ok('no alarms');
  }
  $self->add_perfdata(
      label => 'temperature',
      value => $self->{dupsEnvTemperature},
  );
  if ($self->{dupsEnvHumidity}) {
    $self->add_perfdata(
        label => 'humidity',
        value => $self->{dupsEnvHumidity},
        uom => '%',
    );
  }
}

sub dump {
  my $self = shift;
  printf "[HARDWARE]\n";
  foreach (qw(dupsEnvTemperature dupsAlarmOverEnvHumidity dupsAlarmEnvRelay1 
      dupsAlarmEnvRelay2 dupsAlarmEnvRelay3 dupsAlarmEnvRelay4 
      dupsEnvHumidity dupsEnvSetTemperatureLimit dupsEnvSetHumidityLimit 
      dupsEnvSetEnvRelay1 dupsEnvSetEnvRelay2 dupsEnvSetEnvRelay3
      dupsEnvSetEnvRelay4 dupsAlarmOverEnvTemperature)) {
    printf "%s: %s\n", $_, defined $self->{$_} ? $self->{$_} : 'undefined';
  }
  foreach (qw(dupsAlarmDisconnect dupsAlarmBatteryTestFail dupsAlarmFuseFailure dupsAlarmOutputOverload dupsAlarmOutputOverCurrent dupsAlarmInverterAbnormal dupsAlarmRectifierAbnormal dupsAlarmReserveAbnormal dupsAlarmLoadOnReserve dupsAlarmOverTemperature dupsAlarmOutputBad dupsAlarmPowerFail dupsAlarmBypassBad dupsAlarmClassesOff dupsAlarmChargerFail dupsAlarmFanFail dupsAlarmEconomicMode dupsAlarmOutputOff dupsAlarmSmartShutdown dupsAlarmEmergencyPowerOff dupsAlarmBatteryLow dupsAlarmLoadWarning dupsAlarmLoadSeverity dupsAlarmLoadOnBypass dupsAlarmClassesFault dupsAlarmBatteryGroundFault dupsAlarmTestInProgress)) {
    printf "%s: %s\n", $_, defined $self->{$_} ? $self->{$_} : 'undefined';
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}
