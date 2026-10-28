# frozen_string_literal: true

class SystemInfo
  def hostname
    IO.read("| hostname").strip
  end

  def uptime
    IO.read("/proc/uptime")
  end
end
