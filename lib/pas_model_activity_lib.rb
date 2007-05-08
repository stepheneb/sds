module PasModelActivityLib
  require 'spreadsheet/excel'
  
  # TODO Create a worksheet based on a model.activity.data sock
  def create_worksheet(workbook, sock)
    @count ? nil : @count = []
    @count[sock.pod.id] ? @count[sock.pod.id] += 1 : @count[sock.pod.id] = 1
    ws = workbook.add_worksheet("#{sock.pod.id}:#{@count[sock.pod.id]}")
    mad = get_mad(sock)
    
    row_num = 0
    ws.write(row_num, 0, ["Pod id:", sock.pod.id])
    ws.write(row_num += 1, 0, ["Sock entry id:", sock.id])
    ws.write(row_num += 1, 0, ["Pod id:", sock.pod.id])
    ws.write(row_num += 1, 0, ["Session start: ", sock.bundle.sail_session_start_time.to_s])
    ws.write(row_num += 1, 0, ["Session end:", sock.bundle.sail_session_end_time.to_s])
    if mad
      ws.write(row_num += 1, 0, mad['headers'].collect { |h|  "#{h['name']}\n" << (h['units'] ? "(#{h['units']})\n" : "") << (h['min'] ? "#{h['min']}" : "") << (h['min'] && h['max'] ? "-" : "") << (h['max'] ? "#{h['max']}" : "") } )
      i = 0
      max_column_size = 0
      mad['runs'].each do |r|
        i += 1
        h,m,s,f = DateTime.day_fraction_to_time(DateTime.parse(r['end'].to_s) - DateTime.parse(r['start'].to_s) )
        run_data = "Run #{i}\nStart: #{r['start']}\nEnd: #{r['end']}\nDuration: "
        run_data << (h == 0 ? "" : "#{h} hours, " )
        run_data << (m == 0 ? "" : "#{m} minutes, ")
        run_data << "#{s} seconds"
        ws.write(row_num,0, run_data)
        
        r['by_time'].keys.sort.each do |timex|
          row = []
          
          event_list = r['by_time'][timex]
          row << timex.to_s
          
          # FIXME nasty embedded loop which allows the data to end up in the right column
          # there's got to be a better way
          mad['headers'].each do |h|
            unless h['name'] == "Run" || h['name'] == "Time"
              column_data = []
              event_list.each do |event|
                if event['name'] == h['name']
                  if event['value'].include? '|'
                    start, final, min, max, avg, num = event['value'].split("|")
                    column_data << "Start: #{start}\nEnd: #{final}\nMin: #{min}\nMax: #{max}\nAvg: #{avg}\nNum: #{num}"
                  else
                    column_data << event['value']
                  end
                end
              end
              row << column_data
              if column_data.size > max_column_size
                max_column_size = column_data.size
              end
            end
          end
          ws.write(row_num,1,row)
          row_num += max_column_size
          max_column_size = 0
        end
      end
    else
      ws.write(row_num += 1, 0, "There was an error rendering the model activity data for this sock entry.")
    end
  end

  def get_mad(sock)
  require 'date'
  
    return_hash = { }
    headers = []
    runs = []
    
    begin
    if ! sock.model_activity_dataset && sock.pod.pas_type == "model_activity_data"
      sock.save
    end
    
    ## Start with the headers
     headers << {
        "name"  => "Run"
     }
     headers << {
        "name"  => "Time",
        "units" => "hh:mm:ss"
     }
    
    sock.model_activity_dataset.computational_input.each do |ci|
      ci_hash = {
        "name"  => ci.name,
        "units" => ci.units,
        "min"   => ci.range_min,
        "max"   => ci.range_max
      }
      
      headers << ci_hash
    end
    
    sock.model_activity_dataset.representational_type.each do |rt|
      # prepend with 'zzz' so that they're sorted to the end of the header columns
      headers << { "name" => rt.name }
    end
    
    ## then runs and their associated data
    sock.model_activity_dataset.model_activity_modelrun.each do |mr|
      time_hash = { }
      civs = { }
      mr.computational_input_value.each do |civ|
        civ_time = ( (civ.time && civ.time != 0) ? Time.at(Float(civ.time)/1000) : "no time")
        civ_hash = {
          "name" => civ.computational_input.name,
          "time"  => civ_time,
          "value" => civ.value
        }
        civs[civ.computational_input.name] = civ_hash
        (time_hash[custom_time_string(civ_time)] ||= [] ) << civ_hash
      end
      
      mrvs = { }
      mr.representational_value.each do |mrv|
        mrv_time = ( (mrv.time && mrv.time != 0) ? Time.at(Float(mrv.time)/1000) : "no time");
        hash = { "name" => mrv.representational_attribute.representational_type.name,
                 "time" => mrv_time,
                 "value" => mrv.representational_attribute.value
               }
        mrvs[mrv.representational_attribute.representational_type.name] = hash
        (time_hash[custom_time_string(mrv_time)]  ||= []) << hash
      end
      
      run = {
        "start" => ( (mr.start_time && mr.start_time != 0) ? Time.at(Float(mr.start_time)/1000) : "no time"),
        "end"   => ( (mr.end_time && mr.end_time != 0) ? Time.at(Float(mr.end_time)/1000) : "no time"),
        "civs"  => civs,
        "mrvs"  => mrvs,
        "by_time" => time_hash
      }
      
      runs.push(run)
    end
    
    return_hash = {"headers" => headers, "runs" => runs}
    return return_hash
		rescue => e
		   flash[:notice] = "#{e}<br/><br/>#{e.backtrace.join('<br/>')}"
			 return nil
		end
  end
  
  protected
  
  def custom_time_string(timex)
    if timex == "no time"
      return timex
    else
      return sprintf("%02d:%02d:%02d",timex.hour.to_s, timex.min.to_s, timex.sec.to_s)
    end
  end
end
