require 'sync'

require 'enumerator'
require "ostruct"

require 'more_core_extensions/core_ext/hash'
require 'VMwareWebService/MiqHostDatastoreSystem'
require 'VMwareWebService/MiqHostStorageSystem'
require 'VMwareWebService/MiqHostFirewallSystem'
require 'VMwareWebService/MiqHostServiceSystem'
require 'VMwareWebService/MiqHostNetworkSystem'
require 'VMwareWebService/MiqHostVirtualNicManager'
require 'VMwareWebService/MiqHostAdvancedOptionManager'
require 'VMwareWebService/MiqHostSnmpSystem'

class MiqVimHost
  attr_reader :name, :invObj

  def initialize(invObj, hh)
    @invObj                 = invObj
    @sic                    = invObj.sic
    @cfManager        = nil

    @configManager      = nil
    @datastoreSystem    = nil
    @storageSystem      = nil
    @firewallSystem     = nil
    @serviceSystem      = nil
    @networkSystem      = nil
    @hostVirtualNicManager  = nil
    @advancedOptionManager  = nil
    @snmpSystem       = nil
    @dvsConfig        = nil

    @hh           = hh
    @name                   = hh['summary']['config']['name']
    @hMor         = hh['summary']['host']
  end # def initialize

  def release
    # @invObj.releaseObj(self)
  end

  def hMor
    (@hMor)
  end

  def hh
    (@hh)
  end

  #
  # HostCapability
  #

  def maintenanceModeSupported?
    capabilityBool("maintenanceModeSupported")
  end

  def nfsSupported?
    capabilityBool("nfsSupported")
  end

  def rebootSupported?
    capabilityBool("rebootSupported")
  end

  def sanSupported?
    capabilityBool("sanSupported")
  end

  def shutdownSupported?
    capabilityBool("shutdownSupported")
  end

  def standbySupported?
    capabilityBool("standbySupported")
  end

  def storageVMotionSupported?
    capabilityBool("storageVMotionSupported")
  end

  def vmotionSupported?
    capabilityBool("vmotionSupported")
  end

  def vmotionWithStorageVMotionSupported?
    capabilityBool("vmotionWithStorageVMotionSupported")
  end

  def capabilityBool(cn)
    return nil unless (cap = @hh['capability'])
    cap[cn] == "true"
  end
  private :capabilityBool

  def quickStats
    @invObj.getMoProp(@hMor, "summary.quickStats")['summary']['quickStats']
  end

  def inMaintenanceMode?
    @invObj.getMoProp(@hMor, "runtime.inMaintenanceMode")['runtime']['inMaintenanceMode'] == "true"
  end

  def powerState
    @invObj.getMoProp(@hMor, "runtime.powerState")['runtime']['powerState']
  end

  def enterMaintenanceMode(timeout = 0, evacuatePoweredOffVms = false, wait = true)
    $vim_log.info "MiqVimHost(#{@invObj.server}, #{@invObj.username}).enterMaintenanceMode: calling enterMaintenanceMode_Task" if $vim_log
    taskMor = @invObj.enterMaintenanceMode_Task(@hMor, timeout, evacuatePoweredOffVms)
    $vim_log.info "MiqVimHost(#{@invObj.server}, #{@invObj.username}).enterMaintenanceMode: returned from enterMaintenanceMode_Task" if $vim_log
    return taskMor unless wait
    waitForTask(taskMor)
  end

  def exitMaintenanceMode(timeout = 0, wait = true)
    $vim_log.info "MiqVimHost(#{@invObj.server}, #{@invObj.username}).exitMaintenanceMode: calling exitMaintenanceMode_Task" if $vim_log
    taskMor = @invObj.exitMaintenanceMode_Task(@hMor, timeout)
    $vim_log.info "MiqVimHost(#{@invObj.server}, #{@invObj.username}).exitMaintenanceMode: returned from exitMaintenanceMode_Task" if $vim_log
    return taskMor unless wait
    waitForTask(taskMor)
  end

  def powerDownHostToStandBy(timeout = 0, evacuatePoweredOffVms = false, wait = true)
    $vim_log.info "MiqVimHost(#{@invObj.server}, #{@invObj.username}).powerDownHostToStandBy: calling powerDownHostToStandBy_Task" if $vim_log
    taskMor = @invObj.powerDownHostToStandBy_Task(@hMor, timeout, evacuatePoweredOffVms)
    $vim_log.info "MiqVimHost(#{@invObj.server}, #{@invObj.username}).powerDownHostToStandBy: returned from powerDownHostToStandBy_Task" if $vim_log
    return taskMor unless wait
    waitForTask(taskMor)
  end

  def powerUpHostFromStandBy(timeout = 0, wait = true)
    $vim_log.info "MiqVimHost(#{@invObj.server}, #{@invObj.username}).powerUpHostFromStandBy: calling powerUpHostFromStandBy_Task" if $vim_log
    taskMor = @invObj.powerUpHostFromStandBy_Task(@hMor, timeout)
    $vim_log.info "MiqVimHost(#{@invObj.server}, #{@invObj.username}).powerUpHostFromStandBy: returned from powerUpHostFromStandBy_Task" if $vim_log
    return taskMor unless wait
    waitForTask(taskMor)
  end

  def rebootHost(force = false, wait = true)
    $vim_log.info "MiqVimHost(#{@invObj.server}, #{@invObj.username}).rebootHost: calling rebootHost_Task" if $vim_log
    taskMor = @invObj.rebootHost_Task(@hMor, force)
    $vim_log.info "MiqVimHost(#{@invObj.server}, #{@invObj.username}).rebootHost: returned from rebootHost_Task" if $vim_log
    return taskMor unless wait
    waitForTask(taskMor)
  end

  def shutdownHost(force = false, wait = true)
    $vim_log.info "MiqVimHost(#{@invObj.server}, #{@invObj.username}).shutdownHost: calling shutdownHost_Task" if $vim_log
    taskMor = @invObj.shutdownHost_Task(@hMor, force)
    $vim_log.info "MiqVimHost(#{@invObj.server}, #{@invObj.username}).shutdownHost: returned from shutdownHost_Task" if $vim_log
    return taskMor unless wait
    waitForTask(taskMor)
  end

  def configManager(mgr_type = nil)
    if @configManager.nil?
      mgr = @invObj.getMoProp(@hMor, "configManager")
      @configManager = mgr['configManager'] unless mgr.nil?
    end

    return @configManager[mgr_type] if mgr_type && @configManager
    @configManager
  end

  def datastoreSystem
    return @datastoreSystem if @datastoreSystem
    return nil unless (dss = configManager('datastoreSystem'))
    @datastoreSystem = MiqHostDatastoreSystem.new(dss, @invObj)
    @datastoreSystem
  end

  def storageSystem
    return @storageSystem if @storageSystem
    return nil unless (hss = configManager('storageSystem'))
    @storageSystem = MiqHostStorageSystem.new(hss, @invObj)
    @storageSystem
  end

  def firewallSystem
    return @firewallSystem if @firewallSystem
    return nil unless (fws = configManager('firewallSystem'))
    @firewallSystem = MiqHostFirewallSystem.new(fws, @invObj)
    @firewallSystem
  end

  def serviceSystem
    return @serviceSystem if @serviceSystem
    return nil unless (ss = configManager('serviceSystem'))
    @serviceSystem = MiqHostServiceSystem.new(ss, @invObj)
    @serviceSystem
  end

  def networkSystem
    return @networkSystem if @networkSystem
    return nil unless (ns = configManager('networkSystem'))
    @networkSystem = MiqHostNetworkSystem.new(ns, @invObj)
    @networkSystem
  end

  def hostVirtualNicManager
    raise "hostVirtualNicManager not supported in VIM #{@invObj.apiVersion}" if @invObj.v2
    return @hostVirtualNicManager if @hostVirtualNicManager
    return nil unless (vns = configManager('virtualNicManager'))
    @hostVirtualNicManager = MiqHostVirtualNicManager.new(vns, @invObj)
    @hostVirtualNicManager
  end

  def advancedOptionManager
    return @advancedOptionManager if @advancedOptionManager
    return nil unless (ao = configManager('advancedOption'))
    @advancedOptionManager = MiqHostAdvancedOptionManager.new(ao, @invObj)
    @advancedOptionManager
  end

  def snmpSystem
    return @snmpSystem if @snmpSystem
    return nil unless (ss = configManager('snmpSystem'))
    @snmpSystem = MiqHostSnmpSystem.new(ss, @invObj)
    @snmpSystem
  end

  def hostConfigSpec
    VimHash.new('HostConfigSpec') do |hcs|
      hcs.datastorePrincipal = @hh.config.datastorePrincipal if @hh.config.datastorePrincipal

      hcs.firewall = VimHash.new('HostFirewallConfig') do |hfc|
        fi = firewallSystem.firewallInfo
        hfc.defaultBlockingPolicy = fi.defaultPolicy
        hfc.rule = VimArray.new('ArrayOfHostFirewallConfigRuleSetConfig') do |hfcrca|
          fi.ruleset.each do |rs|
            hfcrca << VimHash.new('HostFirewallConfigRuleSetConfig') do |hfcrc|
              hfcrc.enabled = rs.enabled
              hfcrc.rulesetId = rs.key
            end
          end
        end
      end

      hcs.service = VimArray.new('ArrayOfHostServiceConfig') do |hsca|
        serviceSystem.serviceInfo.service.each do |svc|
          hsca << VimHash.new('HostServiceConfig') do |hsc|
            hsc.serviceId   = svc.key
            hsc.startupPolicy = svc.policy
          end
        end
      end

      hcs.nicTypeSelection = VimArray.new('ArrayOfHostVirtualNicManagerNicTypeSelection') do |_hvnmntsa|
      end
    end
  end

  def fileSystemVolume(selSpec = nil)
    if selSpec.nil?
      return @invObj.getMoProp(@hMor, "config.fileSystemVolume")
    else
      propPath = @invObj.selSpecToPropPath(selSpec)
      sd = @invObj.getMoProp(@hMor, propPath)
      return @invObj.applySelector(sd, selSpec)
    end
  end

  def storageDevice(selSpec = nil)
    if selSpec.nil?
      return @invObj.getMoProp(@hMor, "config.storageDevice")
    else
      propPath = @invObj.selSpecToPropPath(selSpec)
      sd = @invObj.getMoProp(@hMor, propPath)
      return @invObj.applySelector(sd, selSpec)
    end
  end

  ########################
  # Custom field methods.
  ########################

  def cfManager
    @cfManager = @invObj.getMiqCustomFieldsManager unless @cfManager
    @cfManager
  end

  def setCustomField(name, value)
    fk = cfManager.getFieldKey(name, @hMor.vimType)
    cfManager.setField(@hMor, fk, value)
  end

  ######################################
  # Distributed virtual switch methods.
  ######################################

  def dvsConfig(refresh = false)
    return @dvsConfig unless refresh || !@dvsConfig
    @dvsConfig = @invObj.queryDvsConfigTarget(@invObj.sic.dvSwitchManager, @hMor, nil)
  end

  def dvsPortGroupByFilter(filter, refresh = false)
    @invObj.applyFilter(dvsConfig(refresh).distributedVirtualPortgroup, filter)
  end

  def dvsSwitchByFilter(filter, refresh = false)
    @invObj.applyFilter(dvsConfig(refresh).distributedVirtualSwitch, filter)
  end

  def waitForTask(tmor)
    @invObj.waitForTask(tmor, self.class.to_s)
  end
end # class MiqVimHost
