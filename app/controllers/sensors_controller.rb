class SensorsController < ApplicationController
  before_action :set_sensor, only: [:show, :update, :destroy, :generate_random_data, :formated_data]

  # GET /sensors
  def index
    @sensors = Sensor.all

    render json: @sensors
  end

  # GET /sensors/1
  def show
    render json: @sensor, include: ['sensor_errors']
  end

  # POST /sensors
  def create
    @sensor = Sensor.new(sensor_params)

    if @sensor.save
      render json: @sensor, status: :created, location: @sensor
    else
      render json: @sensor.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /sensors/1
  def update
    if @sensor.update(sensor_params)
      render json: @sensor
    else
      render json: @sensor.errors, status: :unprocessable_entity
    end
  end

  # DELETE /sensors/1
  def destroy
    @sensor.destroy
  end

  # Create random records sensor for every 6 hours
  def generate_random_data
    number_of_items = params['number_of_items']
    seedData = Array.new(number_of_items.to_i) { rand*100 }
    seedModels = Array.new
    initialTime = Time.now

    seedData.each_with_index do |d, index|
      seedModels.push({
        value: d,
        created_at: initialTime - 6*60*60*index,
        sensor: @sensor
      })
    end

    data = SensorRecord.create(seedModels)

    render json: {
      'success': true
    }
  end

  def formated_data
    filterType = params["filterType"]
    records = nil

    if filterType == nil
      records = @sensor.sensor_record.order(:register_date)
    elsif filterType == 'all'
      records = @sensor.sensor_record.order(:register_date)
    elsif filterType == 'lastDay'
      records = SensorRecord.created(1, @sensor)
    elsif filterType == 'lastWeek'
      records = SensorRecord.created(7, @sensor)
    elsif filterType == 'lastMonth'
      records = SensorRecord.created(30, @sensor)
    end

    x = Array.new
    y = Array.new

    records.each do |r|
      y.push(r.value.round(2))
      x.push(r.register_date)
    end

    render json: {
      'x': x,
      'y': y,
      'label': "#{@sensor.name} (#{@sensor.scale})"
    }
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sensor
      @sensor = Sensor.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def sensor_params
      ActiveModelSerializers::Deserialization.jsonapi_parse(params)
    end

    def rand_array(x, max)
      x.times.map{ Random.rand(max) }
    end
end
