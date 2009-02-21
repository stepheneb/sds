module ProcessLogger

  def log_memory(cust, smem = 0)
    pid = Process.pid
    mem = process_memory(pid)
    req = request.env["REQUEST_URI"]
    if smem == 0
      logger.info("#{cust} -- PID: #{pid} -- MEM: #{mem} -- METHOD: #{request.method.to_s} -- REQ: #{req}")
    else
      logger.info("#{cust} -- PID: #{pid} -- MEM: #{mem} -- DELTA: #{mem.to_i - smem.to_i} -- METHOD: #{request.method.to_s} -- REQ: #{req}")
    end
    return mem
  end
  
  # Returns process size in kB
  def process_memory(pid = Process.pid)
    str = `ps -o vsz -p #{pid}`
    mem = str[/[0-9]+/].to_i
  end

end