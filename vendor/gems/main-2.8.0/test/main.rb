$:.unshift '.'
$:.unshift './lib'
$:.unshift '..'
$:.unshift '../lib'

require 'stringio'
require 'test/unit'
require 'main'

class T < Test::Unit::TestCase
  attribute 'status'
  attribute 'logger'
  attribute 'error'

  def setup
    @status = nil 
    @logger = Logger.new StringIO.new
    @error = nil
  end

  def teardown
  end

  def main argv=[], env={}, &b
    at_exit{ exit! }

    $VERBOSE=nil
    ARGV.replace argv
    ENV.clear
    env.each{|k,v| ENV[k.to_s]=v.to_s}

    this = self

    klass = ::Main.create do
      module_eval &b if b

      define_method :handle_exception do |e|
        if e.respond_to? :status
          this.status = e.status
        else
          raise
        end
      end

      define_method :handle_throw do |*a|
      end
    end

    main = klass.new argv, env

    main.logger = @logger

    begin
      main.run
    ensure
      this.status ||= main.exit_status
    end

    main
  end

#
# basic test
#
  def test_0000
    assert_nothing_raised{
      main{
        def run() end
      }
    }
  end
  def test_0010
    x = nil
    assert_nothing_raised{
      main{
        define_method(:run){ x = 42 }
      }
    }
    assert x == 42
  end
#
# exit status
#
  def test_0020
    assert_nothing_raised{
      main{
        def run() end
      }
    }
    assert status == 0
  end
  def test_0030
    assert_nothing_raised{
      main{
        def run() exit 42 end
      }
    }
    assert status == 42
  end
  def test_0040
    assert_nothing_raised{
      fork{
        main{
          def run() exit! 42 end
        }
      }
      Process.wait
      assert $?.exitstatus == 42 
    }
  end
  def test_0050
    assert_nothing_raised{
      main{
        def run() exit 42 end
      }
    }
    assert status == 42 
  end
  def test_0060
    assert_nothing_raised{
      main{
        def run() raise ArgumentError end
      }
    }
    assert status == 1
  end
  def test_0060
    assert_raises(RuntimeError){
      main{
        def run() exit_status 42; raise end
      }
    }
    assert status == 42 
  end
  def test_0070
    assert_raises(ArgumentError){
      main{
        def run() exit_status 42; raise ArgumentError end
      }
    }
    assert status == 42 
  end
#
# parameter parsing 
#
  def test_0080
    p = nil
    assert_raises(Main::Parameter::NotGiven){
      main(){
        argument 'foo'
        define_method('run'){ }
      }
    }
  end
  def test_0090
    p = nil
    m = nil
    argv = %w[ 42 ]
    given = nil
    assert_nothing_raised{
      main(argv.dup){
        argument 'foo'
        define_method('run'){ m = self; p = param['foo'] }
      }
    }
    assert p.value == argv.first 
    assert p.values == argv
    assert p.given?
    assert m.argv.empty? 
  end
  def test_0100
    p = nil
    argv = %w[]
    given = nil
    assert_nothing_raised{
      main(argv){
        p = argument('foo'){ optional }
        define_method('run'){ p = param['foo'] }
      }
    }
    assert p.optional?
    assert !p.required?
    assert p.value == nil 
    assert p.values == [] 
    assert !p.given?
  end
  def test_0101
    p = nil
    argv = %w[]
    given = nil
    assert_nothing_raised{
      main(argv){
        p = argument('foo'){ required false }
        define_method('run'){ p = param['foo'] }
      }
    }
    assert p.optional?
    assert !p.required?
    assert p.value == nil 
    assert p.values == [] 
    assert !p.given?
  end
  def test_0110
    p = nil
    argv = %w[ --foo ]
    assert_nothing_raised{
      main(argv){
        option('foo'){ required }
        define_method('run'){ p = param['foo'] }
      }
    }
    assert p.value == true 
    assert p.values ==[true] 
    assert p.given?
  end
  def test_0120
    p = nil
    argv = [] 
    assert_nothing_raised{
      main(argv){
        option 'foo'
        define_method('run'){ p = param['foo'] }
      }
    }
    assert p.value == nil 
    assert p.values == [] 
    assert !p.given?
  end
  def test_0130
    p = nil 
    assert_nothing_raised{
      main(%w[--foo=42]){
        option('foo'){ required; argument_required }
        define_method('run'){ p = param['foo']}
      }
    }
    assert p.required?
    assert p.argument_required?
    assert !p.optional?
  end
  def test_0131
    assert_raises(Main::Parameter::NotGiven){
      main(){
        option('foo'){ required; argument_required }
        define_method('run'){}
      }
    }
  end
  def test_0140
    assert_raises(Main::Parameter::MissingArgument){
      main(['--foo']){
        option('foo'){ required; argument_required }
        define_method('run'){}
      }
    }
  end
  def test_0150
    param = nil
    assert_nothing_raised{
      main(%w[--foo=42 --bar=42.0 --foobar=true --barfoo=false --uri=http://foo --x=s]){
        option('foo'){ 
          required
          argument_required
          cast :int
        }
        option('bar'){ 
          argument_required
          cast :float
        }
        option('foobar'){ 
          argument_required
          cast :bool
        }
        option('barfoo'){ 
          argument_required
          cast :string
        }
        option('uri'){ 
          argument_required
          cast :uri
        }
        option('x'){ 
          argument_required
          cast{|x| x.to_s.upcase}
        }
        define_method('run'){ param = params }
      }
    }
    assert param['foo'].value == 42
    assert param['bar'].value == 42.0
    assert param['foobar'].value == true 
    assert param['barfoo'].value == 'false' 
    assert param['uri'].value == URI.parse('http://foo') 
    assert param['x'].value == 'S' 
  end
  def test_0160
    p = nil 
    assert_nothing_raised{
      main(%w[--foo=42]){
        option('foo'){ 
          required
          argument_required
          cast :int
          validate{|x| x == 42}
        }
        define_method('run'){ p = param['foo']}
      }
    }
    assert p.value == 42
    assert p.required?
    assert p.argument_required?
    assert !p.optional?
  end
  def test_0170
    assert_raises(Main::Parameter::InValid){
      main(%w[--foo=40]){
        option('foo'){ 
          required
          argument_required
          cast :int
          validate{|x| x == 42}
        }
        define_method('run'){ }
      }
    }
  end
  def test_0180
    assert_nothing_raised{
      main(%w[--foo=42]){
        option('--foo=foo'){ 
          required
          # argument_required
          cast :int
          validate{|x| x == 42}
        }
        define_method('run'){ }
      }
    }
  end
  def test_0190
    assert_raises(Main::Parameter::MissingArgument){
      main(%w[--foo]){
        option('--foo=foo'){ }
        define_method('run'){ }
      }
    }
  end
  def test_0200
    p = nil
    assert_nothing_raised{
      main(%w[--foo]){
        option('--foo=[foo]'){ }
        define_method('run'){ p = param['foo'] }
      }
    }
    assert p.value == true
  end
  def test_0210
    p = nil
    assert_nothing_raised{
      main(%w[--foo=42]){
        option('--foo=[foo]'){
          cast :int
          validate{|x| x == 42}
        }
        define_method('run'){ p = param['foo'] }
      }
    }
    assert p.value == 42 
  end
  def test_0220
    p = nil
    assert_nothing_raised{
      main(%w[--foo=40 --foo=2]){
        option('--foo=foo'){
          arity 2
          cast :int
          validate{|x| x == 40 or x == 2}
        }
        define_method('run'){ p = param['foo'] }
      }
    }
    assert p.value == 40
    assert p.values == [40,2]
  end
  def test_0230
    p = nil
    assert_nothing_raised{
      main(%w[foo=42]){
        keyword('foo'){
          cast :int
          validate{|x| x == 42}
        }
        define_method('run'){ p = param['foo'] }
      }
    }
    assert p.value == 42
  end
  def test_0240
    foo = nil
    bar = nil
    assert_nothing_raised{
      main(%w[foo= bar]){
        keyword 'foo'
        keyword 'bar'
        define_method('run'){ 
          foo = param['foo'] 
          bar = param['bar'] 
        }
      }
    }
    assert foo.value == ''
    assert bar.value == nil 
  end
  def test_0250
    foo = nil
    bar = nil
    assert_nothing_raised{
      main(%w[foo=40 bar=2]){
        keyword('foo'){
          cast :int
        }
        keyword('bar'){
          cast :int
        }
        define_method('run'){ 
          foo = param['foo'] 
          bar = param['bar'] 
        }
      }
    }
    assert foo.value == 40 
    assert bar.value == 2 
  end
  def test_0260
    foo = nil
    bar = nil
    foobar = nil
    assert_nothing_raised{
      main(%w[foo=40 --bar=2 foobar foo=42]){
        kw('foo'){ cast :int; arity 2 }
        opt('bar='){ cast :int }
        arg 'foobar'

        define_method('run'){ 
          foo = param['foo'] 
          bar = param['bar'] 
          foobar = param['foobar'] 
        }
      }
    }
    assert foo.value == 40 
    assert foo.values == [40, 42]
    assert bar.value == 2 
    assert foobar.value == 'foobar' 
  end
  def test_0270
    foo = nil
    assert_nothing_raised{
      main([], 'foo' => '42'){
        env('foo'){ cast :int }
        define_method('run'){ 
          foo = param['foo'] 
        }
      }
    }
    assert foo.value == 42 
  end
#
# usage
#
  def test_0280
    assert_nothing_raised{
      u = Main::Usage.new
    }
  end
  def test_0290
    assert_nothing_raised{
      u = Main::Usage.default Main.create
    }
  end
  def test_0300
    assert_nothing_raised{
      chunk = <<-txt
        a
        b
        c
      txt
      assert Main::Util.unindent(chunk) == "a\nb\nc"
      chunk = <<-txt
        a
          b
           c
      txt
      assert Main::Util.unindent(chunk) == "a\n  b\n   c"
    }
  end
  def test_0310
    assert_nothing_raised{
      u = Main::Usage.new
      u[:name] = 'foobar'
      assert u[:name] = 'foobar'
      assert u['name'] = 'foobar'
    }
  end
  def test_0320
    assert_nothing_raised{
      u = Main::Usage.new
      u[:name] = 'foobar'
        assert u[:name] == 'foobar'
        assert u['name'] == 'foobar'
      u[:name2] = 'barfoo'
        assert u[:name] == 'foobar'
        assert u['name'] == 'foobar'
        assert u[:name2] == 'barfoo'
        assert u['name2'] == 'barfoo'
      u.delete_at :name
        assert u[:name] == nil
        assert u['name'] == nil
        assert u[:name2] == 'barfoo'
        assert u['name2'] == 'barfoo'
      u.delete_at :name2
        assert u[:name] == nil
        assert u['name'] == nil
        assert u[:name2] == nil
        assert u['name2'] == nil
    }
  end
#
# io redirection
#
  class ::Object
    require 'tempfile'
    def infile buf
      t = Tempfile.new rand.to_s
      t << buf
      t.close
      open t.path, 'r+'
    end
    def outfile
      t = Tempfile.new rand.to_s
      t.close
      open t.path, 'w+'
    end
  end
  def test_0330
    s = "foo\nbar\n"
    sio = StringIO.new s 
    $buf = nil
    assert_nothing_raised{
      main{
        stdin sio
        def run
          $buf = STDIN.read
        end
      }
    }
    assert $buf == s
  end
  def test_0340
    s = "foo\nbar\n"
    $sio = StringIO.new s 
    $buf = nil
    assert_nothing_raised{
      main{
        def run
          self.stdin = $sio
          $buf = STDIN.read
        end
      }
    }
    assert $buf == s
  end
  def test_0350
    s = "foo\nbar\n"
    $buf = nil
    assert_nothing_raised{
      main{
        stdin infile(s) 
        def run
          $buf = STDIN.read
        end
      }
    }
    assert $buf == s
  end
  def test_0360
    sout = outfile
    assert_nothing_raised{
      main{
        stdout sout 
        def run
          puts 42
        end
      }
    }
    assert test(?e, sout.path)
    assert IO.read(sout.path) == "42\n" 
  end
  def test_0370
    m = nil
    assert_nothing_raised{
      m = main{
        stdout StringIO.new 
        def run
          puts 42
        end
      }
    }
    assert m
    assert_nothing_raised{ m.stdout.rewind }
    assert m.stdout.read == "42\n" 
  end
#
# main ctor
#
  def test_0380
    argv = %w( a b c )
    $argv = nil
    assert_nothing_raised{
      main(argv){
        def run
          $argv = @argv
        end
      }
    }
    assert argv == $argv 
  end
  def test_0390
    argv = %w( a b c )
    env = {'key' => 'val', 'foo' => 'bar'}
    $argv = nil
    $env = nil
    assert_nothing_raised{
      main(argv, env){
        def run
          $argv = @argv
          $env = @env
        end
      }
    }
    assert argv == $argv 
  end

#
# negative/globbing arity
#
  def test_4000
    m = nil
    argv = %w( a b c )
    assert_nothing_raised{
      main(argv.dup) {
        argument('zero_or_more'){ arity -1 }
        run{ m = self }
      }
    }
    assert m.param['zero_or_more'].values == argv
  end 
  def test_4010
    m = nil
    argv = %w( a b c )
    assert_nothing_raised{
      main(argv.dup) {
        argument('zero_or_more'){ arity '*' }
        run{ m = self }
      }
    }
    assert m.param['zero_or_more'].values == argv
  end 
  def test_4020
    m = nil
    argv = %w( a b c )
    assert_nothing_raised{
      main(argv.dup) {
        argument('one_or_more'){ arity -2 }
        run{ m = self }
      }
    }
    assert m.param['one_or_more'].values == argv
  end 
  def test_4030
    m = nil
    argv = %w( a b c )
    assert_nothing_raised{
      main(argv.dup) {
        argument('two_or_more'){ arity -3 }
        run{ m = self }
      }
    }
    assert m.param['two_or_more'].values == argv
  end 
  def test_4040
    m = nil
    argv = %w()
    assert_nothing_raised{
      main(argv.dup) {
        argument('zero_or_more'){ arity -1 }
        run{ m = self }
      }
    }
    assert m.param['zero_or_more'].values == argv
  end 
  def test_4050
    m = nil
    argv = %w()
    assert_raises(Main::Parameter::NotGiven){
      main(argv.dup) {
        argument('one_or_more'){ arity -2 }
        run{ m = self }
      }
    }
  end 
  def test_4060
    m = nil
    argv = %w( a )
    assert_raises(Main::Parameter::Arity){
      main(argv.dup) {
        argument('two_or_more'){ arity -3 }
        run{ m = self }
      }
    }
  end 
  def test_4070
    m = nil
    argv = %w( a )
    assert_raises(Main::Parameter::Arity){
      main(argv.dup) {
        argument('two_or_more'){ arity -4 }
        run{ m = self }
      }
    }
  end 
#
# sub-command/mode functionality
#
  def test_4080
    m = nil
    argv = %w( a b )
    assert_nothing_raised{
      main(argv.dup) {
        mode 'a' do
          argument 'b'
          run{ m = self }
        end
      }
    }
    assert m.param['b'].value == 'b'
  end 
  def test_4090
    m = nil
    argv = %w( a b c )
    assert_nothing_raised{
      main(argv.dup) {
        mode 'a' do
          mode 'b' do
            argument 'c'
            run{ m = self }
          end
        end
      }
    }
    assert m.param['c'].value == 'c'
  end 

end


