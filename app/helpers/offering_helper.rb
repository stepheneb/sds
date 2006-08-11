module OfferingHelper
  def jnlp_resources(xml, name)
    xml.resources {
      xml.j2se("version" => "1.4", "max-heap-size" => "128m", "initial-heap-size" => "32m")
      xml.jar("href" => "jars/loader.jar")
      xml.jar("href" => "jars/framework.jar")
      xml.jar("href" => "jars/otrunk.jar", "main" => "true")
      xml.jar("href" => "jars/data.jar")
      xml.jar("href" => "jars/datagraph.jar")
      xml.jar("href" => "jars/jug-1.1.jar")
      xml.jar("href" => "jars/frameworkview.jar")
      xml.jar("href" => "jars/jdom-1.0.jar")
      xml.jar("href" => "jars/graph.jar")
      xml.jar("href" => "jars/graphutil.jar")
      xml.jar("href" => "jars/swing.jar")
      xml.jar("href" => "jars/portfolio.jar")
      xml.jar("href" => "jars/sensor.jar")
      xml.property("name" => "otrunk.view.single_user", "value" => "true")
    }
  end

end
