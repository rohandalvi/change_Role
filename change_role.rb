require './connect.rb'
puts "Connected"


def build_query(type,fetch,string,order)
  
  query = RallyAPI::RallyQuery.new()
  query.type=type
  query.fetch=fetch
  query.query_string=string
  query.order = order
  
  result = @rally.find(query)
  
  result
end

def initialize
  @projectCount = 0
  @processedCount = 0
  @child_array = Array.new
  @parent_array = Array.new
  @count = true
  result = build_query(:project,"Name,Children","(Name = \"Teams\")","Name Asc")
  
  if(result!=nil)
    result.each{|res|
      @projectCount+=1
      @processedCount = 0
      res.read
      recursive_algorithm(res.Name)

      @parent_array.each{|project|
      beginning = Time.now
      puts "Now processing #{project}"
      get_project_ref(project.strip)
       
      if(@flag==true)
        get_team_members(project.strip)
      end
        puts "Time elapsed: #{(Time.now - beginning)/60} seconds"
      }
      
      
      }
  else
    puts "No results"
  end
end
  def get_project_ref(projectName)
    result = build_query(:project,"Name","(Name = \"#{projectName}\")","Name Asc")
    
    if(result!=nil)
      @flag = true
      result.each{|res|
        res.read
      @project_ref = res._ref
      puts @project_ref
        }
      else
        @flag = false
    end
  end
  
  #get entire branch of projects recursively.
  def recursive_algorithm(parentProject)
     
      @parent_array.push(parentProject)
        while @child_array.length!=0 || @count==true
          @count=false
          @child_array.pop
          
          result = build_query(:project,"Name,Children","(Name = \"#{parentProject}\")","")
          if(result!=nil)
          result.each{ |res|
            res.read
            
            res.Children.results.each{|element|
           
            @child_array.push(element.to_s.strip)
           
           }    
         } 
          end
        
         @child_array.length!=0?recursive_algorithm(@child_array.fetch(-1)):return 
        end #end of while

  end #end of function 

  def get_team_members(projectName)
    
    
    result = build_query(:user,"DisplayName,UserPermissions","","DisplayName Asc")
    
    result.each{|res|
      res.read
      @user_ref = res._ref
      
      res.UserPermissions.results.each{|project|
       
        flag=true
        if project.to_s.start_with? "USD Portfolio"
            flag = false
            @processedCount += 1
            if(@processedCount%100==0)
            end
            obj = {}
            obj["user"] = {"_ref" => @user_ref.strip}
            obj["Role"] = "Editor"
            obj["Project"] = {"_ref" => @project_ref.strip}
            new_projectPermission = @rally.create("projectpermission",obj)
            
        end
        if(flag==false)
          break
        end
      
        }

      }
    
    
  end
initialize