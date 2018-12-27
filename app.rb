require 'sinatra'
require 'sequel'
require 'logger'
require 'json'

logger = Logger.new($stdout)
db = Sequel.connect('sqlite://urlmap.db', logger: logger)
guru_club_releases = db[:project_name]

db.create_table? :project_name do
  primary_key :id, auto_increment: true
  String :ci_environment_slug, index: true
  String :fir_download_url
  String :fir_release_id
  DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP, index: true
end

before do
  content_type 'text/plain'
end

# 下载链接
get '/download_url' do
  slug = params['ci_environment_slug']

  row = guru_club_releases.where(ci_environment_slug: slug).first

  if row
    download_url = row[:fir_download_url]
    release_id = row[:fir_release_id]
    redirect "#{download_url}?release_id=#{release_id}"
  else
    halt 404, 'Could not find corespond release'
  end
end

put '/download_url' do
  request.body.rewind
  json = JSON.parse request.body.read

  slug = json['ci_environment_slug']
  release_id = json['fir_release_id']
  download_url = json['fir_download_url']

  pass unless !slug.nil? || !slug.empty?
  pass unless !release_id.nil? || !release_id.empty?
  pass unless !download_url.nil? || !download_url.empty?
  
  guru_club_releases.insert(ci_environment_slug: slug, 
                            fir_release_id: release_id,
                            fir_download_url: download_url)

  'Success'
end

