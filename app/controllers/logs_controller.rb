class LogsController < ApplicationController
include ApplicationHelper

    def show
        id = params[:id]
        location = id.split(LOCATION_PREFIX)[1] rescue ""
        id = id.split(LOCATION_PREFIX)[0] rescue id
        id = id.delete_prefix("did:oyd:")

        @log = DidLog.find_by_oyd_hash(id)
        if @log.nil?
            didHash = id
        else
            didHash = @log.did
        end
        logs = DidLog.where(did: didHash).pluck(:item).map { |i| JSON.parse(i) } rescue []

        # identify if TERMINATE entry has already revocation record
        logs = add_next(logs)

        # add all log entries that came before (use previous)
        logs = add_previous(logs)

        render json: logs.sort_by { |el| el["ts"] }.to_json, 
               status: 200
    end

    def create
        did = params[:did]
        @log = DidLog.new(did: did, item: params[:log].to_json, oyd_hash: oyd_hash(params[:log].to_json), ts: Time.now.to_i)
        if @log.save
            render plain: "", 
                   status: 200
        else
            render json: {"error": "failed to save log entry"},
                   status: 500
        end
    end

    def add_next(logs)
        new_entries = []
        logs.each do |log|
            if log["op"] == 0 # TERMINATE
                @log = DidLog.find_by_oyd_hash(remove_location(log["doc"]))
                if !@log.nil?
                    tmp = DidLog.where(did: @log.did).pluck(:item).map { |i| JSON.parse(i) } rescue []
                    tmp.delete(log)
                    new_entries << tmp
                    new_entries << add_next(tmp)
                end
            end
        end
        [new_entries, logs].compact.flatten.uniq
    end

    def add_previous(logs)
        new_dids = []
        new_entries = []
        logs.each do |log|
            if log["previous"] != []
                log["previous"].each do |entry|
                    @log = DidLog.find_by_oyd_hash(entry)
                    if !@log.nil?
                        new_dids << @log.did
                    end
                end
            end
        end
        if new_dids.count > 0
            new_dids = new_dids.uniq
            new_entries = DidLog.where(did: new_dids).pluck(:item).map { |i| JSON.parse(i) } rescue []
            more_entries = add_previous(new_entries)
        end
        [new_entries, more_entries, logs].compact.flatten.uniq
    end

    def remove_location(id)
        location = id.split(LOCATION_PREFIX)[1] rescue ""
        id = id.split(LOCATION_PREFIX)[0] rescue id
        id.delete_prefix("did:oyd:")

    end

end