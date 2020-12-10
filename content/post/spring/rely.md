---
title: "spring的循环依赖"
date: 2020-10-27T16:47:00+08:00

tags: ["spring"]
categories: ["spring"]
---

## 什么是循环依赖
循环依赖指的是多个对象之间的依赖关系形成一个闭环。

如果在日常开发中我们用new 对象的方式发生这种循环依赖的话程序会在运行时一直循环调用,直至内存溢出报错。
Spring中，有两种循环依赖的场景
- 第一种：构造器的循环依赖,会抛出异常 BeanCreationException,提示你出现了循环依赖
- 第二种：setter的依赖注入
第一种方式无法解决循环依赖,第二种可以使用提前暴露对象的方式进行解决

## 为什么要避免循环依赖
循环依赖不仅仅是`Spring`的`Bean`之间会产生,往大了看,系统模块之间会产生循环依赖,系统与系统之间也会产生循环依赖,我们应该尽量避免。循环依赖会为系统带来很多意想不到的问题,下面我们来简单讨论一下
- 环状依赖关系不稳定
- 循环依赖会导致内存溢出

## 检测循环依赖的算法
检测环依赖本质就是在检测一个图中是否出现了环,使用深度优先或者广度优先算法去遍历有向图,利用一个 HashSet 依次记录这个依赖关系方向中出现的元素,当出现重复元素时就说明产生了环,而且这个重复元素就是环的起点。
参考下图,红色的节点就代表是循环出现的点
![spring加载示意图](/img/spring/rely/1.jpg)

## spring解决循环依赖的办法
Spring bean的创建，其本质上还是一个对象的创建,一个完整的对象包含两部分:当前对象实例化和对象属性的实例化。在Spring中，对象的实例化是通过反射实现的,而对象的属性则是在对象实例化之后通过一定的方式设置的。

bean工厂 -> 实例化bean -> 初始化bean 

循环依赖解决是通过:Spring先是用实例化Bean对象,此时Spring会将这个实例化结束的对象放到一个Map中，并且Spring提供了获取这个未设置属性的实例化对象引用的方法。

### 一个例子
```java
@Component
public class A {

  private B b;

  public void setB(B b) {
    this.b = b;
  }
}

@Component
public class B {

  private A a;

  public void setA(A a) {
    this.a = a;
  }
}
```
A和B中各自都以对方为自己的全局属性。这里首先需要说明的一点是，Spring实例化bean是通过``ApplicationContext.getBean()``方法来进行的。

如果要获取的对象依赖了另一个对象，那么其首先会创建当前对象，然后通过递归的调用``ApplicationContext.getBean()``方法来获取所依赖的对象，最后将获取到的对象注入到当前对象中。

我们以上面的首先初始化A对象实例为例进行讲解。

首先Spring尝试通过``ApplicationContext.getBean()``方法获取A对象的实例，由于Spring容器中还没有A对象实例，因而其会创建一个A对象，然后发现其依赖了B对象，因而会尝试递归的通过``ApplicationContext.getBean()``方法获取B对象的实例，但是Spring容器中此时也没有B对象的实例，因而其还是会先创建一个B对象的实例

此时A对象和B对象都已经创建了，并且保存在Spring容器中了，只不过A对象的属性b和B对象的属性a都还没有设置进去。

在前面Spring创建B对象之后，Spring发现B对象依赖了属性A，因而此时还是会尝试递归的调用``ApplicationContext.getBean()``方法获取A对象的实例，因为Spring中已经有一个A对象的实例，虽然只是半成品（其属性b还未初始化），但其也还是目标bean，因而会将该A对象的实例返回。

此时，B对象的属性a就设置进去了，然后还是``ApplicationContext.getBean()``方法递归的返回，也就是将B对象的实例返回，此时就会将该实例设置到A对象的属性b中。

这个时候，注意A对象的属性b和B对象的属性a都已经设置了目标对象的实例了。读者朋友可能会比较疑惑的是，前面在为对象B设置属性a的时候，这个A类型属性还是个半成品。

但是需要注意的是，这个A是一个引用，其本质上还是最开始就实例化的A对象。

而在上面这个递归过程的最后，Spring将获取到的B对象实例设置到了A对象的属性b中了，这里的A对象其实和前面设置到实例B中的半成品A对象是同一个对象，其引用地址是同一个，这里为A对象的b属性设置了值，其实也就是为那个半成品的a属性设置了值。

![spring加载示意图](/img/spring/rely/1.jepg)


## 源码
获取bean的入口``ApplicationContext.getBean()``方法由``AbstractBeanFactory.getBean()``实现,它调用了``AbstractBeanFactory.doGetBean`` 方法，下面是getBean执行的流程：
![spring加载示意图](/img/spring/rely/4.png)

```java
public abstract class AbstractBeanFactory extends FactoryBeanRegistrySupport implements ConfigurableBeanFactory {
    /**
     * Return an instance, which may be shared or independent, of the specified bean.
     * @param name the name of the bean to retrieve 要检索bean的名称
     * @param requiredType the required type of the bean to retrieve 要检索bean的类型
     * @param args arguments to use when creating a bean instance using explicit arguments 显式参数创建Bean实例时要使用的参数
     * (only applied when creating a new instance as opposed to retrieving an existing one)
     * @param typeCheckOnly whether the instance is obtained for a type check, 
     * not for actual use
     * @return an instance of the bean
     * @throws BeansException if the bean could not be created
     */
    @SuppressWarnings("unchecked")
    protected <T> T doGetBean(final String name, @Nullable final Class<T> requiredType,
            @Nullable final Object[] args, boolean typeCheckOnly) throws BeansException {
        //转化成固定格式的beanname,如果beanname前面有&,那么去掉&,因为并不用访问工厂本身实例,只需要访问其引用的对象
        //具体可以参考:https://stackoverflow.com/questions/49199901/what-does-the-mean-in-in-a-bean-name
        final String beanName = transformedBeanName(name);
        Object bean;
    
        //1.尝试从缓存中获取目标对象,获取不到就实例化当前对象 XXX 关联下方getSingleton方法
        Object sharedInstance = getSingleton(beanName);
        if (sharedInstance != null && args == null) {
            if (logger.isTraceEnabled()) {
                if (isSingletonCurrentlyInCreation(beanName)) {
                    logger.trace("Returning eagerly cached instance of singleton bean '" + beanName +
                            "' that is not fully initialized yet - a consequence of a circular reference");
                } else {
                    logger.trace("Returning cached instance of singleton bean '" + beanName + "'");
                }
            }
            bean = getObjectForBeanInstance(sharedInstance, name, beanName, null);
        } else {
            // Fail if we're already creating this bean instance:
            // We're assumably within a circular reference.
            // 检测是否开始创建bean了
            if (isPrototypeCurrentlyInCreation(beanName)) {
                throw new BeanCurrentlyInCreationException(beanName);
            }
            // Check if bean definition exists in this factory.
            // 当前工厂不包含bean的定义的时候,去父类工厂里面去找
            BeanFactory parentBeanFactory = getParentBeanFactory();
            if (parentBeanFactory != null && !containsBeanDefinition(beanName)) {
                // Not found -> check parent.
                String nameToLookup = originalBeanName(name);
                if (parentBeanFactory instanceof AbstractBeanFactory) {
                    return ((AbstractBeanFactory) parentBeanFactory).doGetBean(
                            nameToLookup, requiredType, args, typeCheckOnly);
                }
                else if (args != null) {
                    // Delegation to parent with explicit args.
                    return (T) parentBeanFactory.getBean(nameToLookup, args);
                }
                else if (requiredType != null) {
                    // No args -> delegate to standard getBean method.
                    return parentBeanFactory.getBean(nameToLookup, requiredType);
                }
                else {
                    return (T) parentBeanFactory.getBean(nameToLookup);
                }
            }
    
            if (!typeCheckOnly) {
                //将对应bean标记为已创建
                markBeanAsCreated(beanName);
            }
    
            try {
                //从配置文件中拿到之前对bean的定义
                final RootBeanDefinition mbd = getMergedLocalBeanDefinition(beanName);
                checkMergedBeanDefinition(mbd, beanName, args);
    
                // Guarantee initialization of beans that the current bean depends on.
                // 这里的 mbd.getDependsOn() 只有在 配置了 depend-on 标签的时候，才会解析，有值。！！！ 
                // eg:<bean id="aService" class="com.zzf.spring.dependent.AService" depends-on="bService"/>
                String[] dependsOn = mbd.getDependsOn();
                if (dependsOn != null) {
                    for (String dep : dependsOn) {
                        //广度优先遍历这个依赖是否已经被加载过一次,如果是说明没走上面缓存,不应该出现在这或者出现了循环依赖
                        if (isDependent(beanName, dep)) {
                            throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                                    "Circular depends-on relationship between '" + beanName + "' and '" + dep + "'");
                        }
                        //把即将依赖的bean加载到一个Map<String, Set<String>> dependentBeanMap缓存内,以便之后快速查找
                        registerDependentBean(dep, beanName);
                        try {
                            //调用所有所依赖bean,让他们都实例化
                            getBean(dep);
                        }
                        catch (NoSuchBeanDefinitionException ex) {
                            throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                                    "'" + beanName + "' depends on missing bean '" + dep + "'", ex);
                        }
                    }
                }
                
                //3.实例化对象
                //singleton为单例模式，即scope="singleton"的bean，在容器中，只实例化一次。
                if (mbd.isSingleton()) {
                    //XXX 关联下方getSingleton方法
                    sharedInstance = getSingleton(beanName, () -> {
                        try {
                            //XXX 关联下方createBean方法
                            //createBean 是 AbstractAutowireCapableBeanFactory 实现的，内部调用了 doCreateBean 方法
                            //doCreateBean 承担了 bean 的实例化(如果需求)，依赖注入等职责。
                            return createBean(beanName, mbd, args);
                        }
                        catch (BeansException ex) {
                            // Explicitly remove instance from singleton cache: It might have been put there
                            // eagerly by the creation process, to allow for circular reference resolution.
                            // Also remove any beans that received a temporary reference to the bean.
                            destroySingleton(beanName);
                            throw ex;
                        }
                    });
                    bean = getObjectForBeanInstance(sharedInstance, name, beanName, mbd);
                }
                //singleton为原形模式，即scope="singleton"的bean，在容器中，可以实力化任意次
                else if (mbd.isPrototype()) {
                    // It's a prototype -> create a new instance.
                    Object prototypeInstance = null;
                    try {
                        beforePrototypeCreation(beanName);
                        prototypeInstance = createBean(beanName, mbd, args);
                    }
                    finally {
                        afterPrototypeCreation(beanName);
                    }
                    bean = getObjectForBeanInstance(prototypeInstance, name, beanName, mbd);
                }
    
                else {
                    //不存在scope
                    String scopeName = mbd.getScope();
                    final Scope scope = this.scopes.get(scopeName);
                    if (scope == null) {
                        throw new IllegalStateException("No Scope registered for scope name '" + scopeName + "'");
                    }
                    //自定义scope方法
                    try {
                        Object scopedInstance = scope.get(beanName, () -> {
                            beforePrototypeCreation(beanName);
                            try {
                                return createBean(beanName, mbd, args);
                            }
                            finally {
                                afterPrototypeCreation(beanName);
                            }
                        });
                        bean = getObjectForBeanInstance(scopedInstance, name, beanName, mbd);
                    }
                    catch (IllegalStateException ex) {
                        throw new BeanCreationException(beanName,
                                "Scope '" + scopeName + "' is not active for the current thread; consider " +
                                "defining a scoped proxy for this bean if you intend to refer to it from a singleton",
                                ex);
                    }
                }
            }
            catch (BeansException ex) {
                cleanupAfterBeanCreationFailure(beanName);
                throw ex;
            }
        }
    
        // Check if required type matches the type of the actual bean instance.
        //如果需要转换类型,则需要转换类型
        if (requiredType != null && !requiredType.isInstance(bean)) {
            try {
                T convertedBean = getTypeConverter().convertIfNecessary(bean, requiredType);
                if (convertedBean == null) {
                    throw new BeanNotOfRequiredTypeException(name, requiredType, bean.getClass());
                }
                return convertedBean;
            }
            catch (TypeMismatchException ex) {
                if (logger.isTraceEnabled()) {
                    logger.trace("Failed to convert bean '" + name + "' to required type '" +
                            ClassUtils.getQualifiedName(requiredType) + "'", ex);
                }
                throw new BeanNotOfRequiredTypeException(name, requiredType, bean.getClass());
            }
        }
        return (T) bean;
    }

}

```


![spring加载示意图](/img/spring/rely/2.jpg)

``singletonFactory.getObject()``内部其实就是调用doCreateBean方法
```java
public class DefaultSingletonBeanRegistry extends SimpleAliasRegistry implements SingletonBeanRegistry {
    /** 维护着所有创建完成的Bean */
    private final Map<String, Object> singletonObjects = new ConcurrentHashMap<String, Object>(256);
    
    /** 维护着创建中Bean的ObjectFactory,ObjectFactory由doCreateBean创建 用于解决循环依赖问题*/
    private final Map<String, ObjectFactory<?>> singletonFactories = new HashMap<String, ObjectFactory<?>>(16);
    
    /** 维护着所有半成品的Bean 用于解决循环依赖问题 */
    private final Map<String, Object> earlySingletonObjects = new HashMap<String, Object>(16);
    
    
    @Override
    @Nullable
    public Object getSingleton(String beanName) {
        return getSingleton(beanName, true);
    }
    
    /**
     * Return the (raw) singleton object registered under the given name.
     * <p>Checks already instantiated singletons and also allows for an early
     * reference to a currently created singleton (resolving a circular reference).
     * @param beanName the name of the bean to look for
     * @param allowEarlyReference whether early references should be created or not
     * @return the registered singleton object, or {@code null} if none found
     */
    @Nullable
    protected Object getSingleton(String beanName, boolean allowEarlyReference) {
        // 从singletonObjects获取已创建的Bean
        Object singletonObject = this.singletonObjects.get(beanName);
        if (singletonObject == null && isSingletonCurrentlyInCreation(beanName)) {
            synchronized (this.singletonObjects) {
                // 从earlySingletonObjects获取已经实例化的Bean
                singletonObject = this.earlySingletonObjects.get(beanName);
                if (singletonObject == null && allowEarlyReference) {
                    // 从singletonFactories获取ObjectFactory
                    ObjectFactory<?> singletonFactory = this.singletonFactories.get(beanName);
                    if (singletonFactory != null) {
                        //创建实例,实际上就是在调用doCreateBean方法
                        singletonObject = singletonFactory.getObject();
                        //保存实例
                        this.earlySingletonObjects.put(beanName, singletonObject);
                        //移除工厂
                        this.singletonFactories.remove(beanName);
                    }
                }
            }
        }
        return singletonObject;
    }
    
    /**
     * Return the (raw) singleton object registered under the given name,
     * creating and registering a new one if none registered yet.
     * @param beanName the name of the bean
     * @param singletonFactory the ObjectFactory to lazily create the singleton
     * with, if necessary
     * @return the registered singleton object
     */
    public Object getSingleton(String beanName, ObjectFactory<?> singletonFactory) {
        Assert.notNull(beanName, "Bean name must not be null");
        synchronized (this.singletonObjects) {
            //尝试用缓存:singletonObjects获取实例
            Object singletonObject = this.singletonObjects.get(beanName);
            if (singletonObject == null) {
                if (this.singletonsCurrentlyInDestruction) {
                    throw new BeanCreationNotAllowedException(beanName,
                            "Singleton bean creation not allowed while singletons of this factory are in destruction " +
                            "(Do not request a bean from a BeanFactory in a destroy method implementation!)");
                }
                if (logger.isDebugEnabled()) {
                    logger.debug("Creating shared instance of singleton bean '" + beanName + "'");
                }
                beforeSingletonCreation(beanName);
                boolean newSingleton = false;
                boolean recordSuppressedExceptions = (this.suppressedExceptions == null);
                if (recordSuppressedExceptions) {
                    this.suppressedExceptions = new LinkedHashSet<>();
                }
                try {
                    //创建新的Bean，实际就是调用createBean方法
                    singletonObject = singletonFactory.getObject();
                    //标记这是一个新bean
                    newSingleton = true;
                }
                catch (IllegalStateException ex) {
                    // Has the singleton object implicitly appeared in the meantime ->
                    // if yes, proceed with it since the exception indicates that state.
                    singletonObject = this.singletonObjects.get(beanName);
                    if (singletonObject == null) {
                        throw ex;
                    }
                }
                catch (BeanCreationException ex) {
                    if (recordSuppressedExceptions) {
                        for (Exception suppressedException : this.suppressedExceptions) {
                            ex.addRelatedCause(suppressedException);
                        }
                    }
                    throw ex;
                }
                finally {
                    if (recordSuppressedExceptions) {
                        this.suppressedExceptions = null;
                    }
                    afterSingletonCreation(beanName);
                }
                if (newSingleton) {
                    // 缓存bean singletonObjects
                    addSingleton(beanName, singletonObject);
                }
            }
            return singletonObject;
        }
    }
}
```

createBean 是 AbstractAutowireCapableBeanFactory 实现的，内部调用了 doCreateBean 方法
doCreateBean 承担了 bean 的实例化，依赖注入等职责。
ObjectFactory是由doCreateBean提供的
![spring加载示意图](/img/spring/rely/3.jpg)
```java
public abstract class AbstractAutowireCapableBeanFactory extends AbstractBeanFactory
      implements AutowireCapableBeanFactory {
    	/**
    	 * Actually create the specified bean. Pre-creation processing has already happened
    	 * at this point, e.g. checking {@code postProcessBeforeInstantiation} callbacks.
    	 * <p>Differentiates between default bean instantiation, use of a
    	 * factory method, and autowiring a constructor.
    	 * @param beanName the name of the bean
    	 * @param mbd the merged bean definition for the bean
    	 * @param args explicit arguments to use for constructor or factory method invocation
    	 * @return a new instance of the bean
    	 * @throws BeanCreationException if the bean could not be created
    	 * @see #instantiateBean
    	 * @see #instantiateUsingFactoryMethod
    	 * @see #autowireConstructor
    	 */
    	protected Object doCreateBean(final String beanName, final RootBeanDefinition mbd, final @Nullable Object[] args)
    			throws BeanCreationException {
    
    		// Instantiate the bean.
    		BeanWrapper instanceWrapper = null;
    		if (mbd.isSingleton()) {
    			instanceWrapper = this.factoryBeanInstanceCache.remove(beanName);
    		}
            //1.createBeanInstance 负责实例化一个 Bean 对象。
    		if (instanceWrapper == null) {
    			instanceWrapper = createBeanInstance(beanName, mbd, args);
    		}
    		final Object bean = instanceWrapper.getWrappedInstance();
    		Class<?> beanType = instanceWrapper.getWrappedClass();
    		if (beanType != NullBean.class) {
    			mbd.resolvedTargetType = beanType;
    		}
    
    		// Allow post-processors to modify the merged bean definition.
    		synchronized (mbd.postProcessingLock) {
    			if (!mbd.postProcessed) {
    				try {
    					applyMergedBeanDefinitionPostProcessors(mbd, beanType, beanName);
    				}
    				catch (Throwable ex) {
    					throw new BeanCreationException(mbd.getResourceDescription(), beanName,
    							"Post-processing of merged bean definition failed", ex);
    				}
    				mbd.postProcessed = true;
    			}
    		}
    
    		// Eagerly cache singletons to be able to resolve circular references
    		// even when triggered by lifecycle interfaces like BeanFactoryAware.
            //2.允许单例Bean的提前暴露,新建并缓存ObjectFactory
    		boolean earlySingletonExposure = (mbd.isSingleton() && this.allowCircularReferences &&
    				isSingletonCurrentlyInCreation(beanName));
    		if (earlySingletonExposure) {
    			if (logger.isTraceEnabled()) {
    				logger.trace("Eagerly caching bean '" + beanName +
    						"' to allow for resolving potential circular references");
    			}
                //新建并缓存ObjectFactory
    			addSingletonFactory(beanName, () -> getEarlyBeanReference(beanName, mbd, bean));
    		}
    
    		// Initialize the bean instance.
    		Object exposedObject = bean;
    		try {
                //3.依赖注入 内部会调用依赖项的getBean
    			populateBean(beanName, mbd, instanceWrapper);
    			exposedObject = initializeBean(beanName, exposedObject, mbd);
    		}
    		catch (Throwable ex) {
    			if (ex instanceof BeanCreationException && beanName.equals(((BeanCreationException) ex).getBeanName())) {
    				throw (BeanCreationException) ex;
    			}
    			else {
    				throw new BeanCreationException(
    						mbd.getResourceDescription(), beanName, "Initialization of bean failed", ex);
    			}
    		}
    
    		if (earlySingletonExposure) {
    			Object earlySingletonReference = getSingleton(beanName, false);
    			if (earlySingletonReference != null) {
    				if (exposedObject == bean) {
    					exposedObject = earlySingletonReference;
    				}
    				else if (!this.allowRawInjectionDespiteWrapping && hasDependentBean(beanName)) {
    					String[] dependentBeans = getDependentBeans(beanName);
    					Set<String> actualDependentBeans = new LinkedHashSet<>(dependentBeans.length);
    					for (String dependentBean : dependentBeans) {
    						if (!removeSingletonIfCreatedForTypeCheckOnly(dependentBean)) {
    							actualDependentBeans.add(dependentBean);
    						}
    					}
    					if (!actualDependentBeans.isEmpty()) {
    						throw new BeanCurrentlyInCreationException(beanName,
    								"Bean with name '" + beanName + "' has been injected into other beans [" +
    								StringUtils.collectionToCommaDelimitedString(actualDependentBeans) +
    								"] in its raw version as part of a circular reference, but has eventually been " +
    								"wrapped. This means that said other beans do not use the final version of the " +
    								"bean. This is often the result of over-eager type matching - consider using " +
    								"'getBeanNamesOfType' with the 'allowEagerInit' flag turned off, for example.");
    					}
    				}
    			}
    		}
    
    		// Register bean as disposable.
    		try {
    			registerDisposableBeanIfNecessary(beanName, bean, mbd);
    		}
    		catch (BeanDefinitionValidationException ex) {
    			throw new BeanCreationException(
    					mbd.getResourceDescription(), beanName, "Invalid destruction signature", ex);
    		}
    
    		return exposedObject;
    	}
}
```

## 总结
我们以 A，B 循环依赖注入为例，画了一个完整的注入流程图

![spring加载示意图](/img/spring/rely/4.jpg)

注意上图的黄色节点， 我们再来过一下这个流程

1. 在创建 A 的时候，会将 实例化的A 通过 addSingleFactory（黄色节点）方法缓存, 然后执行依赖注入B。
2. 注入会走创建流程， 最后B又会执行依赖注入A。
3. 由于第一步已经缓存了 A 的引用， 再次创建 A 时可以通过 getSingleton 方法得到这个 A 的提前引用（拿到最开始缓存的 objectFactory， 通过它取得对象引用）， 这样 B 的依赖注入就完成了。
4. B 创建完成后， 代表 A 的依赖注入也完成了，那么 A 也创建成功了 （实际上 Spring 还有 initial 等步骤，不过与我们这次的讨论主题相关性不大）


## 其他
> 1. 构造器注入为什么不能处理循环依赖?

构造器只能初始化一次

> 2. Spring 如何检测循环依赖的细节?

1. 总体思想:DefaultSingletonBeanRegistry.registeredSingletons 来显示一个bean是否暴露来实现,已暴露的对象无法实例化
2. 实现方法:
 - Spring只会解决setter方法注入的循环依赖，构造器注入的循环依赖会抛BeanCurrentlyInCreationException异常。
 - Spring不会解决prototype作用域的bean，因为Spring容器不进行缓存"prototype"作用域的bean，因此无法提前暴露一个创建中的bean。如果有循环依赖会抛BeanCurrentlyInCreationException异常。


