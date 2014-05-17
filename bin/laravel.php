<?php
/**
 *=============================================================================
 * AUTHOR:  Mun Mun Das <m2mdas at gmail.com>
 * FILE: laravel.php
 * Last Modified: September 11, 2013
 * License: MIT license  {{{
 *     Permission is hereby granted, free of charge, to any person obtaining
 *     a copy of this software and associated documentation files (the
 *     "Software"), to deal in the Software without restriction, including
 *     without limitation the rights to use, copy, modify, merge, publish,
 *     distribute, sublicense, and/or sell copies of the Software, and to
 *     permit persons to whom the Software is furnished to do so, subject to
 *     the following conditions:
 *
 *     The above copyright notice and this permission notice shall be included
 *     in all copies or substantial portions of the Software.
 *
 *     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 *     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 *     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 *     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 *     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 *     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 *     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 * }}}
 *=============================================================================
 */


use Illuminate\Foundation\AliasLoader;
use Illuminate\Routing\Router;
use Illuminate\Support\Facades\Facade;
use Illuminate\Support\ServiceProvider;

class laravel
{
    /**
     * @var array 
     */
    private $facades;

    /**
     * bindings list 
     *
     * @var array 
     */
    private $bindings;

    /**
     * list of routes
     *
     * @var array 
     */
    private $routes;

    /**
     * list of controllers 
     *
     * @var array 
     */
    private $controllers;

    /**
     * list of model classes
     */
    private $models;

    /**
     * @var array
     */
    private $providers;

    /**
     * 
     *
     * @var array
     */
    private $ioc_list;

    /**
     * 
     *
     * @var array 
     */
    private $ioc_file;

    /**
     *
     * @var array 
     */
    private $index;

    private $classMap;

    private $managerFQCNS;


    public function __construct()
    {
        $this->facades     = array();
        $this->aliases     = array();
        $this->bindings    = array();
        $this->routes      = array();
        $this->controllers = array();
        $this->index       = array();
        $this->models      = array();
        $this->ioc_list    = array();
        $this->ioc_file    = array();
        $this->providers   = array();
        $this->classMap    = array();
        $this->manageFQCNS = array();
    }

    /**
     * called to check that this plugin script is valid for current project
     *
     * @return bool 
     */
    public function isValidForProject()
    {
        return is_file('bootstrap/start.php');
    }

    /**
     * This hook is called before indexing started. Bootstraping code of the 
     * framework goes here
     */
    public function init($loader)
    {
        //override service providers to process packages
        $this->classMap['Illuminate\Support\ServiceProvider'] = __DIR__.'/wrapper/ServiceProvider.php';
        spl_autoload_register(array($this, 'loadClass'), true, true);

        //autoload workbench packages
        $workbench = getcwd() .'/workbench';
        if(is_dir($workbench)) {
            Illuminate\Workbench\Starter::start($workbench);
        }

        //TODO: Process packages
        global $app;
        $this->app = require_once 'bootstrap/start.php';
        $this->aliases = AliasLoader::getInstance()->getAliases();
        $this->bindings = $this->app->getBindings();
        $providers = $app['config']['app.providers'];
        foreach ($providers as $provider) {
            $providerObj= $this->resolveProviderClass($provider);
            try {
                $providerObj->boot();
            } catch (Exception $e) {
            }
        }


        //AliasLoader::getInstance($this->aliases)->register();
    }

	/**
	 * Resolve a service provider instance from the class name.
	 *
	 * @param  string  $provider
	 * @return \Illuminate\Support\ServiceProvider
	 */
	protected function resolveProviderClass($provider)
	{
		return new $provider($this->app);
	}


    /**
     * Called after a class is processed
     *
     * @param string $fqcn FQCN of the class
     * @param string $file file name of the class
     * @param array $classData processed class info
     */
    public function postProcess($fqcn, $file, $classData)
    {
        $className = $classData['classname'];
        if(array_key_exists("parentclass", $classData) && $classData['parentclass'] == "BaseController") {
            $this->controllers[$className] = $fqcn;
        }

        if(array_key_exists("parentclass", $classData) && $classData['parentclass'] == "Illuminate\Support\Facades\Facade") {
            
            if(!in_array($fqcn, $this->aliases)) {
                return;
            }
            //parse class file
            $startLine = $classData['methods']['all']['getFacadeAccessor']['startLine'];
            $endLine = $classData['methods']['all']['getFacadeAccessor']['endLine'];
            $classContent = file($file);
            $funcContent = array_slice($classContent, $startLine-1, $endLine+2-$startLine);

            $facade_service = '';
            foreach ($funcContent as $line) {
                $line = trim($line);
                if(preg_match("/return\s+'(.*)';/", $line, $matches)){
                    $facade_service = trim($matches[1]);
                }
            }

            $facadeName = array_search($fqcn, $this->aliases);
            $this->facades[$facadeName] = array(
                'facade_service' => $facade_service,
                'facade_fqcn' => $fqcn
            );
        }
        if(array_key_exists('parentclass', $classData) && $classData['parentclass'] == 'Illuminate\Support\Manager') {
            //it is a manager but also a driver, Two-Face :)
            $this->managerFQCNS[$fqcn] = "";
        }
        if(array_key_exists("parentclass", $classData) && $classData['parentclass'] == "Illuminate\Database\Eloquent\Model") {
            $this->models[$className] = array(
                'fqcn' => $fqcn,
                'file' => $file,
            );
        }
        if(array_key_exists("parentclass", $classData) && $classData['parentclass'] == "Illuminate\Support\ServiceProvider") {
            $this->providers[$className] = $fqcn;
        }
    }

    /**
     * Called after main index is created
     *
     * @param mixed $fullIndex the main index
     * @param object $generatorObject the generator object
     */
    public function postCreateIndex($fullIndex, $generatorObject)
    {
        $this->processIndex($fullIndex, $generatorObject);
    }

    /**
     * Called after update script initialized
     *
     * @param mixed $prevIndex the previous index of this plugin
     */
    public function preUpdateIndex($prevIndex)
    {
        $this->controllers = $prevIndex['controllers'];
        $this->models      = $prevIndex['models'];
        $this->ioc_list     = $prevIndex['ioc_list'];
        $this->facades     = $prevIndex['facades'];
        $this->routes      = $prevIndex['routes'];
        $this->providers   = $prevIndex['providers'];
        $this->managerFQCNS = $prevIndex['manager_fqcns'];
    }

    /**
     * Called after update index created
     *
     * @param mixed $classData class data of processed class
     * @param mixed $fullIndex the main index
     * @param object $generatorObject
     */
    public function postUpdateIndex($classData, $fullIndex, $generatorObject)
    {
        $this->processIndex($fullIndex, $generatorObject);
    }

    /**
     * Returns the plugin index
     *
     * @return mixed the index created by this plugin script
     */
    public function getIndex()
    {
        return $this->index;
    }

    public function addClassMap($fqcn, $file)
    {
        $this->classMap[$fqcn] = $file;

    }
    public function loadClass($class)
    {
        if(array_key_exists($class, $this->classMap)) {
            include $this->classMap[$class];
            return true;
        }

    }

    private function processIndex($fullIndex, $generatorObject)
    {
        $this->processIoc($fullIndex, $generatorObject);
        $this->routes = $this->processRouters($fullIndex, $generatorObject);

        $this->index = array(
            'controllers' => $this->controllers,
            'models' => $this->models,
            'ioc_list' => $this->ioc_list,
            'ioc_file' => $this->ioc_file,
            'facades' => $this->facades,
            'routes' => $this->routes,
            'providers' => $this->providers,
            'manager_fqcns' => $this->managerFQCNS
        );
    }

    private function processIoc($fullIndex, $generatorObject)
    {
        $config = $this->app['config'];
        $fqcn_file = $fullIndex['fqcn_file'];
        $iocNames = array_keys($this->bindings);
        foreach ($iocNames as $iocName) {
            try {
                $ioc = $this->app->make($iocName);
            } catch (Exception $e) {
            }
            $this->ioc_file[$iocName] = "";
            if(is_object($ioc)) {
                $iocFQCN = get_class($ioc);
                if(!array_key_exists($iocFQCN, $fqcn_file)) {
                    $ref = new ReflectionClass($iocFQCN);
                    $file = $ref->getFileName();
                    $this->ioc_file[$iocName] = $file;
                } else {
                    $this->ioc_file[$iocName] = $fqcn_file[$iocFQCN];
                }
                $this->ioc_list[$iocName] = $iocFQCN;
            }
        }
        $this->ioc_list['app'] = 'Illuminate\Foundation\Application';
        $this->ioc_file['app'] = $fqcn_file['Illuminate\Foundation\Application'];

        // adding ioc to facades
        foreach ($this->facades as $facade => $values) {
            $facade_service = $values['facade_service'];
            $this->facades[$facade]['facade_service_file'] = "";
            if(array_key_exists($facade_service, $this->ioc_list)) {
                $facade_service_fqcn = $this->ioc_list[$facade_service];
            } else {
                if(empty($facade_service)) {
                    $facade_service ="psr_custom_service". $facade;
                }
                $facade_service_fqcn = get_class($this->app->make($facade)->getFacadeRoot());
                $this->ioc_list[$facade_service] = $facade_service_fqcn;
                $facade_service_file = "";
                if(!array_key_exists($facade_service_fqcn, $fqcn_file)) {
                    $ref = new ReflectionClass($iocFQCN);
                    $file = $ref->getFileName();
                    $this->ioc_file[$facade_service] = $file;
                } else{
                    $this->ioc_file[$facade_service] = $fqcn_file[$facade_service_fqcn];
                }
            }

            $this->facades[$facade]['facade_service_fqcn'] = $facade_service_fqcn;
            $facade_service_file = "";
            if(array_key_exists($facade_service_fqcn, $fqcn_file)) {
                $facade_service_file = $fqcn_file[$facade_service_fqcn];
            }
            $this->facades[$facade]['facade_service_file'] = $facade_service_file;

            //process managers
            if(array_key_exists($facade_service_fqcn, $this->managerFQCNS)) {
                $driverFQCN = get_class($this->app->make($facade)->getFacadeRoot()->driver());
                $this->managerFQCNS[$facade_service_fqcn] = $driverFQCN;
            }
        }
    }

    //private function processFacades()
    //{
        ////getFacadeRoot() static method taking long time
        ////so discarded
        //$facade_fqcn = array();
        //foreach ($this->facades as $facade => $fqcn) {

            //if(!array_key_exists($facade, $this->aliases)) {
                //continue;
            //}

            //if($facade == "Facade") {
                //$this->facade_fqcn[$facade] = array(
                    //'facade_service' => "",
                    //'facade_fqcn' => $fqcn,
                    //'facade_service_file' => "",
                //);
                //continue;
            //}
            //$facade_instance_type = get_class(call_user_func_array($facade."::getFacadeRoot", array()));

            //$facade_fqcn[$facade] = array(
                //'facade_service' => $facade_instance_type,
                //'facade_fqcn' => $facade_fqcn,
                //'facade_service_file' => "",
            //);
        //}
        //$this->facades = $facade_fqcn;
    //}

    private function processRouters($fullIndex, $generatorObject)
    {
        global $app;
        $mainRouter = $this->app->make('router');
        $routerWrapper = new RouterWrapper($this->controllers, $fullIndex);
        //echo $routerWrapper->get("dfsdfa", 'dfssda');
        //exit;
        $this->app->instance('router', $routerWrapper);
        $this->app['router'] = $routerWrapper;
        Facade::clearResolvedInstance('router');
        $app = $this->app;
        require "app/routes.php";
        return $routerWrapper->getRouteInfo();
    }
}


class RouterWrapper extends Router
{
    private $controllers;
    private $fullIndex;
    private $routeInfo;

    public function __construct($controllers, $fullIndex)
    {
        $this->routeInfo = array();
        $this->controllers = $controllers;
        $this->fullIndex = $fullIndex;
    }

    public function getRouteInfo()
    {
        return $this->routeInfo;
    }

    public function get($pattern, $arguments)
    {
        $this->process('get', func_get_args());
    }

    public function put($pattern, $arguments)
    {
        $this->process('put', func_get_args());
    }
    
    public function post($pattern, $arguments)
    {
        $this->process('post', func_get_args());
    }

    public function patch($pattern, $arguments)
    {
        $this->process('patch', func_get_args());
    }

    public function delete($pattern, $arguments)
    {
        $this->process('delete', func_get_args());
    }

    public function any($pattern, $arguments)
    {
        $this->process('any', func_get_args());
    }

    public function resource($pattern, $arguments)
    {
        $this->process('resource', func_get_args());
    }

    public function controller($uri, $controller, $names = array())
    {
        $this->process('controller', func_get_args());
    }

    public function process($name, $arguments)
    {
        $validFuncNames = array('get', 'post', 'put', 'delete', 'patch', 'any', 'resource', 'controller');
        if(!in_array($name, $validFuncNames)) {
            return;
        }
        $pattern = $arguments[0];
        $action  = $arguments[1];

        $info = array();
        $info['pattern'] = $pattern;
        $type = "object";
        if($action instanceof Closure) {
            $type = "closure";
        }
        $info['route_type'] = $type;
        $bt = debug_backtrace();
        $routerStack = $bt[2];
        $positionData =  array(
            'file' => str_replace("\\", "/", @$routerStack['file']),
            'line' => @$routerStack['line'],
        );
        $info['declaration'] = $positionData;

        if($action instanceOf Closure) {
            $info['position'] = $positionData;
        } elseif(is_string($action)) {
            //TODO: for now it checks controllers@method format, will add 
            //namespace and alias option later
            $segments = explode('@', $action);
            $controller = $segments[0];

            if(strpos($controller, "\\") !== false) {
                if(!array_key_exists($controller, $this->fullIndex['fqcn_file'])) {
                    return;
                }
                $fqcn = $controller;
                $file = $this->fullIndex['fqcn_file'][$controller];
            }
            elseif(array_key_exists($controller, $this->controllers)) {
                $fqcn = $this->controllers[$controller];
                $file = $this->fullIndex['fqcn_file'][$controller];
            }
            else {
                return;
            }

            if(!array_key_exists($fqcn, $this->fullIndex['classes'])) {
                return;
            }
            $controllerClassData = $this->fullIndex['classes'][$fqcn];

            if(count($segments) == 1) {
                $line = $controllerClassData['startLine'];
            }
            elseif(count($segments) == 2) {
                $method = $segments[1];
                if(!array_key_exists($method, $controllerClassData['methods']['all'])) {
                    return;
                }
                $line = $controllerClassData['methods']['all'][$method]['startLine'];
            }

            $positionData =  array(
                'file' => $file,
                'line' => $line,
            );
            $info['position'] = $positionData;
        }

        $this->routeInfo[$pattern] = $info;
    }
}

