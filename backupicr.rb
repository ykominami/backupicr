require 'pathname'
require 'pp'
require 'fileutils'

#require 'hashm'

class FSItem
  attr_accessor :path, :name, :ctime, :size, :dir1, :dir2 , :kind , :year, :month, :day

  def initialize( path )
    @path = path
    @name = path.basename
    @kind = path.directory? ? :Directory : :File

    stat = File.stat(path)
    @ctime = stat.ctime
    @year = ctime.year
    @month = ctime.month
    @day = ctime.day

    @size = stat.size
    @dir2 , @dir1 = path.dirname.split

  end

  def set_year( year )
    @year = year
  end
end

class Backupicr
#  include Hashm
  
  def initialize
    @dest_top_dir = Pathname.new("Z:/")
    @dest_top_dirname = "SANYO-ICR/VOICE_IC/A"
    @src_top_dir = Pathname.new("T:/")
    @src_top_dirname = "VOICE_IC"
    @this_year=2011
    @next_year=2012
    @target = {}

    @dest_dir = @dest_top_dir.join( @dest_top_dirname )
    unless File.exists?(@dest_dir)
    end
    %w[E:/ F:/ M:/ T:/ U:/ V:/ W:/ X:/ Y:/].each do |it|
      @src_top_dir = Pathname.new(it)
      @src_dir = @src_top_dir.join( @src_top_dirname )
      if File.exists?(@src_dir)
        puts "Found #{@src_dir}"
        break
      else
        puts "Not found #{@src_dir}"
      end
    end
  end

  def get_src_dir_dest_dir_list( dest_dirs )
    hs = {}
    @target.each do |k,v|
      dirname= sprintf("%4d%02d%02d" , k[0] , k[1] , k[2])
      re = Regexp.new( dirname )
      list = dest_dirs.select{|x| x.name.to_s =~ re }
      hs[k] ||= []
      hs[k] << [dirname, list, v]
    end
    hs
  end

  def get_dest_file_list( dest_dir_list )
    dest_file_list = []
    dest_dir_list.each { |it|
      dest_file_list.concat( 
                            it.path.children.each { |x|
                              x.directory? == false
                            }.collect{ |y|
                              FSItem.new( y ) 
                            } 
                            )
    }
    dest_file_list
  end

  def get_copy_list( src_file_list , dest_file_list )
    copy_list = []
    dfl = dest_file_list
    src_file_list.each do |sf|
      same_flag = false
      cnt = 0
      if dfl.size > 0
        dfl.each do |df|
          if sf.name.to_s == df.name.to_s and sf.size == df.size
            same_flag = true
            break
          end
          cnt += 1
        end
        unless same_flag
#          puts "not same sf.name.to_s=#{sf.name.to_s}|sf.size=#{sf.size}"
          copy_list << sf
        else
#          puts "SAME sf.name.to_s=#{sf.name.to_s}|sf.size=#{sf.size}"
#          puts "cnt=#{cnt}"
          dfl.delete_at(cnt)
        end
      else
        copy_list << sf
      end

    end
    copy_list
  end

  def copy_files( src_file_list , dirname , cnt )
    if cnt > 0 or src_file_list.size > 1
      src_file_list.each do |it|
        destdir = @dest_dir.join( "#{dirname}-#{cnt}" )
        if File.exists?(destdir)
          puts "#{destdir} exist"
        else
          puts "#{destdir} not exist"
          puts "mkdir_p #{destdir}"
          FileUtils.mkdir_p( destdir )
          cnt += 1
          puts "src=#{it.path} -> destdir=#{destdir}"
          FileUtils.cp( it.path , destdir )
        end
      end
    else
      destdir = @dest_dir.join( dirname )
      x = src_file_list.first
      if File.exists?(destdir)
        puts "#{destdir} exist"
      else
        puts "#{destdir} not exist"
        puts "mkdir_p #{destdir}"
        FileUtils.mkdir_p( destdir )
        puts "src=#{x.path} -> destdir=#{destdir}"
        FileUtils.cp( x.path , destdir )
      end
    end
  end

  def get_max_number_from_dir_list(dest_dir_list)
    max = dest_dir_list.collect { |it|
      tmp,num = it.name.to_s.split("-")
      if num
        number = num.to_i
      else
        number = 0
      end
      number
    }.max
    max
  end

  def exec
    get_target_files.each do |it|
=begin
      if it.month > 8
        it.set_year( @this_year )
      else
        it.set_year( @next_year )
      end
=end
      k = [it.year , it.month , it.day]
      @target[ k ] ||= []
      @target[ k ] << it
    end
    
    dest_dirs = get_dest_dirs
    hs = get_src_dir_dest_dir_list( dest_dirs )
    hs.each do |k,v|
      v.each do |it|
        dirname = it[0]
        dest_dir_list = it[1]
        src_file_list = it[2]
        if dest_dir_list and dest_dir_list.size > 0
          dest_file_list = get_dest_file_list( dest_dir_list )
          copy_list = get_copy_list( src_file_list , dest_file_list )
          if copy_list and copy_list.size > 0
            max = get_max_number_from_dir_list(dest_dir_list)
            puts "copy_files max+1=#{max+1}"
            copy_files( copy_list , dirname , max + 1 )
          end
        else
          puts "copy_files 1"
          copy_files( src_file_list , dirname , 1 )
        end
      end
    end
  end
  
  def get_dest_dirs
    @dest_dir.children.select{ |x| 
      x.directory? 
    }.collect{ |y| 
      FSItem.new( y ) 
    }
  end

  def get_target_files
    targetfiles = []
    @src_dir.children.each do |dir|
      dir.children.each do |fpath|
        unless fpath.directory?
          targetfiles << FSItem.new( fpath )
        end
      end
    end
    targetfiles
  end
end

bicr = Backupicr.new
bicr.exec

